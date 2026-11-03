# Base de datos BioRed

Documentación del modelo relacional de la plataforma: usuarios, grupos, etiquetas, solicitudes, accesos, módulos, sensores, visualizaciones y auditoría.

El modelo implementa el esquema de [roles y permisos](https://github.com/AngelPrz8a/BioRed_Roles_y_Permisos): quién puede ver, crear, aprobar y administrar módulos, grupos y visualizaciones. Motor: MySQL 8.0.16 o superior (por el uso de restricciones `CHECK`).

## Contenido

- [Diagrama entidad-relación](#diagrama-entidad-relación) <!--- [Imagen de la base de datos](#imagen-de-la-base-de-datos)-->
- [Roles y permisos en la base de datos](#roles-y-permisos-en-la-base-de-datos)
- [Niveles de visibilidad](#niveles-de-visibilidad)
- [Flujo de solicitudes y accesos](#flujo-de-solicitudes-y-accesos)
- [Descripción de las tablas](#descripción-de-las-tablas)
- [Relaciones](#relaciones)
- [Reglas de integridad](#reglas-de-integridad)
- [Convenciones](#convenciones)

## Diagrama entidad-relación

![Diagrama entidad-relación de BioRed](https://www.plantuml.com/plantuml/png/XLTBR-Cs4BxhLx3keKcG00bGe82HBXPT89SiTWkqEHM5G4kqFGr5gdousJRzxpjyY0z9yUfWI3F3UNwS6R_NXYfZ1zvyPuviO6Ja54HpX9wH3bJ7MQEVGOnKqO7e8-tbFo0EP4-vBZb2zaopaVnuMn0L5S-E-5D9PCA0-KB-QmZvXNRF1oMjw3z8BXNv_i4_ZYDLprIatlgd-RzfujaDC_2tPORg3Q6Qf2-lz8f0tquaSd__w-ExTqY-kS4V8OUTOlZ2CEfUbYgjjbI1R6lL2ses4LdUmlL3CBAqFN6yUQhX8D1kEs9Oz_UHjMVTaRQ1ru4KArvLphpXmqgKdLIAEUvJu7PI64Kr4xGzKdr4YfAyFN2vepmbfUqiMgV9CSKEe8sgadLGTfHjvLnDoYxEwBMdLGWn7TEPYg8bXmwCxLkfuC14PiPAnb3SmUGvubGndRy7sSCUkf3awC7J8xd8NbmdwvUBS8imv-6jvZ-d7Mz6fs2CPa-WOGSSUjedpph55gMdjWU3qKOaviziFD5c3ZWLGNryQy5zq2wwqD71f-b4yNwrL1Y6iQj449QT77i2lp-SIkb0n5vCIclfSoeJ2quNtzdhH5o28RASHrNviOoZ59hkU44tu8D0DXRMyhCGSk2Ob7kq23Wntc96420r9m5gLffy7r3SHj9VLfk4gT9zPnETjavRUQGii3SUgnlUYz9wmZ93Aw6ktQ0onm-Frn68PT1bf5ZIZlMmtfWyKvSPO2yZg2af2h7IlT7J0YyA3jB0IPQq8XTuAIpbyAzd-8nKb9oNchm441Ewz6CjFH4t6DSU3bRLrLsKkseQ9TIzfGddyQC0-UJ8D-hddIdK1dxG6j-pqdHufdHKSWISED_eeskTPzOJfy-wdkYVa7WbTz8OEH2vJwEe6Y5RGli1X9iMg42HrqaCfIuexoW2QKkCx2dXrEqPXkwb6kWbHjyJPs5XfvuUPPVVaW4Ozbc9PZg9wmAuoQegKtWB964yfm9t6hIy1txEPanxdR0j6UqExvGpXwkHC35DchoYOD3-IaO5ft2bBWA9lU2qolO_VVwTV7hw-F6CzTpdrvhk5cCTiT_t65LGwIVt80TqINeoDlSTuk12Wo1uzH6R3kgQgPERwTGAN4vSKXJhhC8Mu-MPIqrGADq9nW4hoKe_Vo0_kuSyOFQ8jgEV6O7MvFLeUZPtswiD0jIzt6sMUrIptAo2P3XojSaGIxl3Myfd89bj746-r1nc-2mY4FioehhFp1HCrxr9ztxDhGb7oSu7AH0F-AFTNCODmG5HHuF9twW5zsmnQIh6w5cvokcpafDlSPqXvsII_xyLq_nB6bbfU4oHb4C_f-IsL7b691Pd9d5NI4J3vqHcY9XXeIpIf6pgjMT4C0-VyL-9ABf8Hiq54voY759yr-1CNpR5pdRp1_wZmiD_ulfwD3TLISj0vd9rIT_ZTNH_rRu2)

<!--## Imagen de la base de datos


Para agregar la imagen:
1. Guarda el archivo en el repositorio, por ejemplo en docs/img/bd.png
2. Borra el bloque de "Espacio reservado" de abajo
3. Descomenta la línea siguiente:

![Imagen de la base de datos](docs/img/bd.png)
-->

## Roles y permisos en la base de datos

Los cuatro roles del documento de roles y permisos se representan así. Cada rol hereda los permisos del anterior (Administrador → Coordinador → Usuario identificado → Usuario particular).

| Rol | Cómo se representa | Alcance |
|---|---|---|
| **Usuario particular** | No se guarda: es quien navega sin sesión. | Solo módulos con visibilidad `publico`. |
| **Usuario identificado** | `usuarios.rol_global = 'usuario'` con cuenta `activa`. | Sus módulos, los de sus grupos y los que le aprueben. |
| **Coordinador** | `grupo_usuarios.rol_grupo = 'coordinador'` (pertenencia `activo`). | Solo el grupo de esa fila. Coordinar un grupo no da permisos sobre otros. |
| **Administrador** | `usuarios.rol_global = 'administrador'`. | Todo el sistema. |

Por esta razón existen **dos campos de rol separados**:

- `usuarios.rol_global` (`administrador` | `usuario`): alcance de toda la plataforma. *Coordinador no es un rol global.*
- `grupo_usuarios.rol_grupo` (`miembro` | `coordinador`): alcance limitado al grupo de la fila.

Un mismo usuario puede ser coordinador de un grupo y simple miembro de otro.

## Niveles de visibilidad

**Módulos** (`modulos.visibilidad`)

| Valor | Quién puede verlo |
|---|---|
| `publico` | Cualquier persona, con o sin sesión. |
| `identificados` | Usuarios con sesión iniciada. |
| `grupo` | Miembros del grupo del módulo. Exige `id_grupo` no nulo. |
| `privado` | Solo su propietario y el administrador. Otros usuarios acceden si tienen un registro vigente en `accesos`. |

**Grupos** (`grupos.visibilidad`)

| Valor | Quién puede verlo |
|---|---|
| `publico` | Cualquier persona. |
| `privado` | Solo sus miembros. |

## Flujo de solicitudes y accesos

Toda solicitud tiene un **destino explícito** según su `tipo`:

| `tipo` | Campos de destino | Quién resuelve | Al aprobarse |
|---|---|---|---|
| `acceso_modulo` | `id_modulo` + `nivel_acceso_solicitado` (`lectura` \| `escritura`) | Coordinador del grupo del módulo o administrador. | Se crea un registro en `accesos` enlazado por `id_solicitud`. |
| `ingreso_grupo` | `id_grupo` + `rol_solicitado` | Coordinador del grupo o administrador. | Se crea (o se reactiva) la fila en `grupo_usuarios` con `id_solicitud_origen`. |
| `cambio_rol_grupo` | `id_grupo` + `rol_solicitado` | Administrador. | Se actualiza `grupo_usuarios.rol_grupo`. |

Los permisos vigentes sobre módulos viven en `accesos`, **separados de la solicitud** que los originó. Así se pueden consultar, revocar y hacer caducar:

- `estado`: `vigente` | `revocado` | `caducado`.
- `fecha_expiracion` (opcional): el evento `ev_caducar_accesos` marca como `caducado` los accesos vencidos cada hora.
- La vista `v_accesos_vigentes` devuelve solo los accesos efectivamente vigentes, considerando también la fecha de expiración.

## Descripción de las tablas

### `usuarios`

Cuentas registradas en el sistema.

| Campo | Clave | Descripción |
|---|---|---|
| `id_usuario` | PK | Identificador del usuario. |
| `nombre` | | Nombre de la persona. |
| `correo` | UK | Correo electrónico, único. |
| `contrasena_hash` | | Contraseña almacenada como hash. |
| `rol_global` | | Rol en toda la plataforma: `administrador` o `usuario` (por defecto). |
| `estado_cuenta` | | Estado de la cuenta: `activa`, `inactiva`, `suspendida` o `pendiente` (por defecto). |
| `fecha_registro` | | Fecha en que se registró. |

### `grupos`

Grupos de trabajo.

| Campo | Clave | Descripción |
|---|---|---|
| `id_grupo` | PK | Identificador del grupo. |
| `nombre` | UK | Nombre del grupo, único. |
| `descripcion` | | Descripción del grupo. |
| `visibilidad` | | Quién puede ver el grupo: `publico` o `privado` (por defecto). |
| `fecha_creacion` | | Fecha de creación. |

### `grupo_usuarios`

Pertenencia de los usuarios a los grupos.

| Campo | Clave | Descripción |
|---|---|---|
| `id_grupo_usuarios` | PK | Identificador de la pertenencia. |
| `id_usuario` | FK, UK* | Usuario que pertenece al grupo. |
| `id_grupo` | FK, UK* | Grupo al que pertenece. |
| `id_solicitud_origen` | FK | Solicitud que originó la pertenencia o el cambio de rol (opcional). |
| `estado` | | Estado de la pertenencia: `activo` (por defecto), `inactivo` o `pendiente`. |
| `rol_grupo` | | Rol dentro de ese grupo: `miembro` (por defecto) o `coordinador`. |
| `fecha_ingreso` | | Fecha en que ingresó al grupo. |
| `fecha_modificacion` | | Fecha de la última modificación. |

\* Clave única compuesta `(id_usuario, id_grupo)`: una sola pertenencia por pareja. Para reingresos se reutiliza la fila cambiando `estado` y fechas.

### `etiquetas`

Catálogo de etiquetas que se asignan a las personas (por ejemplo, "Estudiante de semillero" o "Profesor aliado").

| Campo | Clave | Descripción |
|---|---|---|
| `id_etiqueta` | PK | Identificador de la etiqueta. |
| `nombre` | | Nombre de la etiqueta. |
| `estado` | | Estado de la etiqueta: `activa` (por defecto) o `inactiva`. |

### `usuario_etiquetas`

Etiquetas asignadas a cada usuario.

| Campo | Clave | Descripción |
|---|---|---|
| `id_usuario` | PK, FK | Usuario al que se asigna la etiqueta. |
| `id_etiqueta` | PK, FK | Etiqueta asignada. |
| `asignado_por` | FK | Usuario que realizó la asignación. |
| `fecha_asignacion` | | Fecha de la asignación. |

### `solicitudes`

Solicitudes de acceso a módulos, ingreso a grupos y cambio de rol en un grupo.

| Campo | Clave | Descripción |
|---|---|---|
| `id_solicitud` | PK | Identificador de la solicitud. |
| `id_solicitante` | FK | Usuario que hace la solicitud. |
| `id_responsable` | FK | Usuario que resuelve la solicitud. |
| `tipo` | | `acceso_modulo`, `ingreso_grupo` o `cambio_rol_grupo`. |
| `id_modulo` | FK | Módulo destino (solo `acceso_modulo`). |
| `id_grupo` | FK | Grupo destino (solo `ingreso_grupo` y `cambio_rol_grupo`). |
| `rol_solicitado` | | Rol que se pide en el grupo: `miembro` o `coordinador`. |
| `nivel_acceso_solicitado` | | Nivel que se pide sobre el módulo: `lectura` o `escritura`. |
| `estado` | | `pendiente` (por defecto), `aprobada`, `rechazada` o `cancelada`. |
| `fecha_creacion` | | Fecha en que se creó. |
| `fecha_resolucion` | | Fecha en que se resolvió. Obligatoria si la solicitud ya no está pendiente. |
| `justificacion_solicitante` | | Motivo que da quien solicita. |
| `respuesta_resolucion` | | Respuesta de quien resuelve. |

### `accesos`

Permisos vigentes de un usuario sobre un módulo, separados de la solicitud que los originó.

| Campo | Clave | Descripción |
|---|---|---|
| `id_acceso` | PK | Identificador del acceso. |
| `id_modulo` | FK | Módulo al que se da acceso. |
| `id_usuario` | FK | Usuario que recibe el acceso. |
| `id_solicitud` | FK, UK | Solicitud que lo originó (opcional; una solicitud origina como máximo un acceso). |
| `nivel_acceso` | | `lectura` (por defecto) o `escritura`. |
| `estado` | | `vigente` (por defecto), `revocado` o `caducado`. |
| `concedido_por` | FK | Usuario que concedió el acceso. |
| `fecha_concesion` | | Fecha de la concesión. |
| `fecha_expiracion` | | Fecha de caducidad (opcional). Debe ser posterior a la concesión. |
| `revocado_por` | FK | Usuario que revocó el acceso. |
| `fecha_revocacion` | | Fecha de la revocación. Obligatoria si el estado es `revocado`. |
| `motivo_revocacion` | | Motivo de la revocación. |
| `vigente_flag` | | Columna generada: vale 1 si el acceso está vigente y `NULL` si no. Con su clave única evita dos accesos vigentes para el mismo usuario y módulo. |

### `modulos`

Módulos registrados. Los campos propios de los sensores están en la tabla `sensores`.

| Campo | Clave | Descripción |
|---|---|---|
| `id_modulo` | PK | Identificador del módulo. |
| `id_propietario` | FK | Usuario propietario del módulo. |
| `id_grupo` | FK | Grupo al que pertenece el módulo (obligatorio si la visibilidad es `grupo`). |
| `visibilidad` | | `publico`, `identificados`, `grupo` o `privado` (por defecto). |
| `fecha_modificacion` | | Fecha de la última modificación de la configuración. |
| `modificado_por` | FK | Usuario que hizo la última modificación. |

### `sensores`

Sensores que pertenecen a un módulo.

| Campo | Clave | Descripción |
|---|---|---|
| `id_sensor` | PK | Identificador del sensor. |
| `id_modulo` | FK | Módulo al que pertenece. |
| `tipo` | | Tipo de sensor. |

### `visualizacion`

Paneles y gráficas creados por los usuarios sobre los sensores.

| Campo | Clave | Descripción |
|---|---|---|
| `id_visualizacion` | PK | Identificador de la visualización. |
| `id_sensor` | FK | Sensor que se visualiza. |
| `id_usuario` | FK | Usuario que la creó. |
| `tipo` | | Tipo de visualización (panel o gráfica). |
| `configuracion` | | Configuración de la visualización (JSON). |
| `fecha_creacion` | | Fecha de creación. |
| `fecha_modificacion` | | Fecha de la última modificación. |

### `auditorias`

Registro de cambios: quién, qué y cuándo. No tiene claves foráneas a propósito, para que el historial sobreviva a los datos que describe.

| Campo | Clave | Descripción |
|---|---|---|
| `id_auditoria` | PK | Identificador del registro. |
| `entidad` | | Tabla o entidad afectada. |
| `entidad_id` | | Identificador del registro afectado. |
| `accion` | | Operación realizada: `INSERT`, `UPDATE` o `DELETE`. |
| `campo` | | Campo que cambió. |
| `valor_anterior` | | Valor antes del cambio. |
| `valor_nuevo` | | Valor después del cambio. |
| `usuario_id` | | Usuario que hizo el cambio. |
| `id_grupo_contexto` | | Grupo al que pertenecía el recurso en el momento del cambio (`NULL` si el cambio es global). Permite que el coordinador consulte solo la auditoría de su grupo. |
| `fecha` | | Fecha y hora del cambio. |

Si un módulo cambia de grupo, se registra el cambio de `id_grupo` con el grupo anterior como contexto y, opcionalmente, otra fila con el grupo nuevo.

## Relaciones

| Tabla origen | Tabla destino | Cardinalidad | Campo de enlace |
|---|---|---|---|
| `usuarios` | `grupo_usuarios` | 1:* | `id_usuario` |
| `grupos` | `grupo_usuarios` | 1:* | `id_grupo` |
| `usuarios` | `usuario_etiquetas` | 1:* | `id_usuario`, `asignado_por` |
| `etiquetas` | `usuario_etiquetas` | 1:* | `id_etiqueta` |
| `usuarios` | `solicitudes` | 1:* | `id_solicitante`, `id_responsable` |
| `modulos` | `solicitudes` | 1:* | `id_modulo` (solo `acceso_modulo`) |
| `grupos` | `solicitudes` | 1:* | `id_grupo` (solo `ingreso_grupo` y `cambio_rol_grupo`) |
| `solicitudes` | `accesos` | 1:0..1 | `id_solicitud` |
| `solicitudes` | `grupo_usuarios` | 1:* | `id_solicitud_origen` |
| `usuarios` | `accesos` | 1:* | `id_usuario`, `concedido_por`, `revocado_por` |
| `modulos` | `accesos` | 1:* | `id_modulo` |
| `usuarios` | `modulos` | 1:* | `id_propietario`, `modificado_por` |
| `grupos` | `modulos` | 1:* | `id_grupo` |
| `modulos` | `sensores` | 1:* | `id_modulo` |
| `sensores` | `visualizacion` | 1:* | `id_sensor` |
| `usuarios` | `visualizacion` | 1:* | `id_usuario` |
| `usuarios` | `auditorias` | 1:* | `usuario_id` (lógica, sin FK) |
| `grupos` | `auditorias` | 1:* | `id_grupo_contexto` (lógica, sin FK) |

## Reglas de integridad

| Regla | Dónde |
|---|---|
| El correo de cada usuario es único. | `usuarios.correo` |
| El nombre de cada grupo es único. | `grupos.nombre` |
| Un usuario tiene una sola pertenencia por grupo. | `grupo_usuarios (id_usuario, id_grupo)` |
| Un módulo con visibilidad `grupo` debe tener `id_grupo`. | `CHECK` en `modulos` |
| `acceso_modulo` exige `id_modulo` y `nivel_acceso_solicitado`, y no admite `id_grupo` ni `rol_solicitado`. | `CHECK` en `solicitudes` |
| `ingreso_grupo` y `cambio_rol_grupo` exigen `id_grupo` y `rol_solicitado`, y no admiten `id_modulo` ni `nivel_acceso_solicitado`. | `CHECK` en `solicitudes` |
| Una solicitud que ya no está `pendiente` debe tener `fecha_resolucion`. | `CHECK` en `solicitudes` |
| Un usuario no puede tener dos accesos `vigente` al mismo módulo. | `UNIQUE` con `vigente_flag` en `accesos` |
| Una solicitud origina como máximo un acceso. | `UNIQUE` en `accesos.id_solicitud` |
| Un acceso `revocado` debe tener `fecha_revocacion`. | `CHECK` en `accesos` |
| La expiración debe ser posterior a la concesión. | `CHECK` en `accesos` |
| No se puede eliminar a un usuario que sea propietario de un módulo. | `ON DELETE RESTRICT` en `modulos.id_propietario` |
| No se puede eliminar un grupo o módulo que tenga módulos o solicitudes asociados. | FK sin acción en destinos (MySQL no permite acciones referenciales en columnas usadas en un `CHECK`). |

## Convenciones

| Abreviatura | Significado |
|---|---|
| **PK** | Clave primaria |
| **FK** | Clave foránea |
| **UK** | Clave única |
| **1:\*** | Uno a muchos |
| **1:1** | Uno a uno |
| **1:0..1** | Uno a cero o uno (relación opcional) |
