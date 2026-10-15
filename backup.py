#!/usr/bin/env python3
"""Backup de los 7 routers por la consola de GNS3 (sin copiar a mano).

Uso, desde la carpeta del repo y con el lab encendido y los routers logueados:
    python3 backup.py ~/GNS3/projects/<proyecto>/<proyecto>.gns3 F1

Deja backups/AAAA-MM-DD_<ROUTER>_<FASE>.rsc con la salida de /export terse.
"""
import datetime
import json
import pathlib
import re
import socket
import sys
import time

ROUTERS = {"ISP-1", "ISP-2", "EDGE", "CORE-1", "CORE-2", "DIST-1", "DIST-2"}


def limpiar(raw: bytes) -> str:
    raw = re.sub(rb"\xff[\xfb-\xfe].|\xff[\xf0-\xfa]", b"", raw)  # negociacion telnet
    txt = raw.decode("utf-8", "replace")
    txt = re.sub(r"\x1b\[[0-9;?]*[A-Za-z]", "", txt).replace("\r", "")  # colores
    lineas = txt.split("\n")
    ini = next((i for i, l in enumerate(lineas) if "by RouterOS" in l), None)
    if ini is None:
        return ""
    cuerpo = [l for l in lineas[ini:] if not l.lstrip().startswith("[admin@")]
    return "\n".join(cuerpo).strip() + "\n"


def exportar(puerto: int) -> bytes:
    with socket.create_connection(("localhost", puerto), timeout=5) as s:
        s.settimeout(1)
        s.sendall(b"\r")
        time.sleep(1)
        s.sendall(b"/export terse\r")
        datos, quieto = b"", 0
        while quieto < 4:  # corta tras 4 s sin salida nueva
            try:
                chunk = s.recv(65536)
                if not chunk:
                    break
                datos, quieto = datos + chunk, 0
            except socket.timeout:
                quieto += 1
        return datos


def main():
    proyecto, fase = sys.argv[1], sys.argv[2]
    nodos = json.load(open(proyecto))["topology"]["nodes"]
    hoy = datetime.date.today().isoformat()
    pathlib.Path("backups").mkdir(exist_ok=True)
    for n in nodos:
        if n["name"] not in ROUTERS:
            continue
        texto = limpiar(exportar(n["console"]))
        destino = pathlib.Path(f"backups/{hoy}_{n['name']}_{fase}.rsc")
        if not texto:
            print(f"FALLO {n['name']}: no vino el export (¿router logueado?)")
            continue
        destino.write_text(texto)
        aviso = "  <-- revisar: contiene 'password'" if "password" in texto.lower() else ""
        print(f"ok {destino} ({len(texto.splitlines())} lineas){aviso}")


if __name__ == "__main__":
    main()
