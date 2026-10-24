# Verificación de seguridad — clave incorrecta debe FALLAR

Criterio F4: una adyacencia OSPF y una sesión BGP con clave incorrecta no levantan.
Ejecuta: R3 (OSPF) y R1/R2 (BGP). Guardar la clave original antes de tocar nada.

## OSPF MD5 — DIST-2 con clave incorrecta

```
DIST-2> /routing ospf interface-template print           # anotar el número N de la plantilla de ether1,ether2
DIST-2> /routing ospf interface-template set N auth-key="CLAVEMAL"
```
Esperar hasta 40 s (dead interval).

Resultado esperado:
- `DIST-2> /routing ospf neighbor print`: sin vecinos.
- `CORE-1> /routing ospf neighbor print`: DIST-2 (`10.255.0.5`) ya no aparece.
- `/log print where topics~"ospf"`: errores de autenticación.

Restaurar:
```
DIST-2> /routing ospf interface-template set N auth-key="<K-OSPF-12>"
```
Verificar 2 vecinos Full de nuevo.

| Dato | Valor |
|------|-------|
| Vecinos con clave incorrecta | 0 en DIST-2; CORE-1 queda con 3 y sin 10.255.0.5. Log de DIST-2: authentication failed ... md5 mismatch |
| Tiempo hasta caer la adyacencia | 40 s |
| Vecinos tras restaurar | 2 Full, a los 12 s de restaurar la clave |

Capturas: `capturas/F4/seg_ospf_falla.png`, `seg_ospf_ok.png`.

## BGP TCP-MD5 — ISP-2 con clave incorrecta

```
ISP-2> /routing bgp connection set EDGE tcp-md5-key="CLAVEMAL"
```

Resultado esperado:
- `EDGE> /routing bgp session print`: la sesión ISP-2 no llega a established.
- La salida a Internet sigue por ISP-1 (no hay corte para los hosts).

Restaurar:
```
ISP-2> /routing bgp connection set EDGE tcp-md5-key="<K-BGP-ISP2>"
```

| Dato | Valor |
|------|-------|
| Estado de la sesión con clave incorrecta | No established: Connection closed → Idle al 1 s y siguió así 60 s. PC-USER sin pérdidas (sale por ISP-1) |
| Estado tras restaurar | Established, al 1 s de restaurar la clave |

Capturas: `seg_bgp_falla.png`, `seg_bgp_ok.png`.

## Opcional — VRRP con clave incorrecta

`DIST-2> /interface vrrp set vrrp20 password="CLAVEMAL"`: DIST-1 y DIST-2 dejan de reconocerse y los dos quedan master de vrid 20. Muestra por qué la autenticación de VRRP importa: un equipo con otra clave no puede tomar el gateway. Restaurar con `<K-VRRP-20>`.
