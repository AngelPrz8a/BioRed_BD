# Base de datos BioRed

Documentación del modelo relacional de la plataforma: usuarios, grupos, etiquetas, solicitudes, módulos, sensores, visualizaciones y auditoría.

## Contenido

- [Diagrama entidad-relación](#diagrama-entidad-relación) <!--- [Imagen de la base de datos](#imagen-de-la-base-de-datos)-->
- [Descripción de las tablas](#descripción-de-las-tablas)
- [Relaciones](#relaciones)
- [Convenciones](#convenciones)

## Diagrama entidad-relación

![Diagrama entidad-relación de BioRed](https://www.plantuml.com/plantuml/png/XLNBRjKm4DtdAynb0LHSgPMGa52fAYfrmm8sh12AN7kI37NiCBRB0_5LV08_XXCdTk8RGLRscV4vP_oON5l7oVbULOzS1psmGN7KLOSIc40I2YfxZthWn7jcEoxDLzGjQxYowuWs4YmCxCNv2YIkxqVmvHe4xT1zPpyhnjvmST-IyLhU66M8FRwTlZ5YI0BDwFdqLR-gQbvx08TVF3Xk3unRbcOJwHb3MIyGkxny__RgAi37OyM2o_wE80mWL2tDcj9RpmbDlQNEw8d479eKdjy6aL8xHP8yjzZge5iFXa9q3ZKWEbx7c42ZTrnjpEnxsAjI628OenzYL1ZjY5lGlEwuxG92HgNTg8KFiZmv8cZHEjhiKaj-CFN6LO8ARrkyi9Yzftr8Qp8IVIL3g5i2c-UzaTYWu0B__DPpCQNNxB7qjhzhURCaM44uBEGFQF4E5Kekam514CNNijnBT8QGH-aypV89Aom4Yf4_ZseS9uBtWnajS6Mevje1eQ44Q0yF8PpkAYQ3QrlMA1Jel8JeAyzNnX9O6CkXKRqye9X0O0UZBRzJEM6pJqQlhbQWypFaSAhkixSk7-TQBmH7SX_Kyj9YryFnUAxmnwGp5RX1SebR-BHCq3O_pfsBcWqBenjiFUNIYbgBMreyxQWqdyOooJuZScemq7bLcbdHndXaZUDCcXSNf0EP0S7zxptkFxjvNlIrOEa9Upr-x1OLPzOFqxMDM9KRwl8TBbwT7OAZSN1nEEsyrGaoPyObPsb9oipS1NdHiweqJQiAvjW_YefGD-kADXUh84ZdMos3FLlBUMMT6wFXMw0B-Q0T0Mk2i8t1LEN24lxCUc5QlUv_vcrCxsQMtkPMoegSqlyxag2P1AOuQpQxzHIquW9iGAQUgi0-grPTylYnGnaMVo9iEtVSb9B79tb5ATUWfU_LNm00)

<!--## Imagen de la base de datos


Para agregar la imagen:
1. Guarda el archivo en el repositorio, por ejemplo en docs/img/bd.png
2. Borra el bloque de "Espacio reservado" de abajo
3. Descomenta la línea siguiente:

![Imagen de la base de datos](docs/img/bd.png)
-->

## Descripción de las tablas

### `usuarios`

Cuentas registradas en el sistema.

| Campo | Clave | Descripción |
|---|---|---|
| `id_usuario` | PK | Identificador del usuario. |
| `nombre` | | Nombre de la persona. |
| `correo` | UK | Correo electrónico, único. |
| `contrasena_hash` | | Contraseña almacenada como hash. |
| `rol` | | Rol del usuario en el sistema. |
| `estado_cuenta` | | Estado de la cuenta (por ejemplo, activa o suspendida). |
| `fecha_registro` | | Fecha en que se registró. |

### `grupos`

Grupos de trabajo.

| Campo | Clave | Descripción |
|---|---|---|
| `id_grupo` | PK | Identificador del grupo. |
| `nombre` | UK | Nombre del grupo, único. |
| `descripción` | | Descripción del grupo. |
| `visibilidad` | | Quién puede ver el grupo (público, solo identificados o privado). |
| `fecha_creación` | | Fecha de creación. |

### `grupo_usuarios`

Pertenencia de los usuarios a los grupos.

| Campo | Clave | Descripción |
|---|---|---|
| `id_grupo_usuarios` | PK | Identificador de la pertenencia. |
| `id_usuario` | FK | Usuario que pertenece al grupo. |
| `id_grupo` | FK | Grupo al que pertenece. |
| `estado` | | Estado de la pertenencia. |
| `fecha_ingreso` | | Fecha en que ingresó al grupo. |
| `fecha_modificación` | | Fecha de la última modificación. |
| `rol` | | Rol del usuario dentro del grupo. |

### `etiquetas`

Catálogo de etiquetas que se asignan a las personas.

| Campo | Clave | Descripción |
|---|---|---|
| `id_etiqueta` | PK | Identificador de la etiqueta. |
| `nombre` | | Nombre de la etiqueta. |
| `estado` | | Estado de la etiqueta. |

### `usuario_etiquetas`

Etiquetas asignadas a cada usuario.

| Campo | Clave | Descripción |
|---|---|---|
| `id_usuario` | PK, FK | Usuario al que se asigna la etiqueta. |
| `id_etiqueta` | PK, FK | Etiqueta asignada. |
| `asignado_por` | FK | Usuario que realizó la asignación. |
| `fecha_asignacion` | | Fecha de la asignación. |

### `solicitudes`

Solicitudes de acceso, ingreso a grupos y cambio de rol.

| Campo | Clave | Descripción |
|---|---|---|
| `id_solicitud` | PK | Identificador de la solicitud. |
| `id_solicitante` | FK | Usuario que hace la solicitud. |
| `estado` | | Estado de la solicitud (por ejemplo, pendiente, aprobada o rechazada). |
| `id_responsable` | FK | Usuario que resuelve la solicitud. |
| `fecha_creacion` | | Fecha en que se creó. |
| `fecha_resolucion` | | Fecha en que se resolvió. |
| `tipo` | | Tipo de solicitud. |
| `justificación_solicitante` | | Motivo que da quien solicita. |
| `respuesta_resolución` | | Respuesta de quien resuelve. |

### `modulos`

Módulos registrados. Los campos propios de los sensores están en la tabla `sensores`.

| Campo | Clave | Descripción |
|---|---|---|
| `id_modulo` | PK | Identificador del módulo. |
| `id_propietario` | FK | Usuario propietario del módulo. |
| `id_grupo` | FK | Grupo al que pertenece el módulo. |
| `fecha_modificación` | | Fecha de la última modificación de la configuración. |
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
| `configuracion` | | Configuración de la visualización. |
| `fecha_creacion` | | Fecha de creación. |
| `fecha_modificacion` | | Fecha de la última modificación. |

### `auditorias`

Registro de cambios: quién, qué y cuándo.

| Campo | Clave | Descripción |
|---|---|---|
| `id_auditoria` | PK | Identificador del registro. |
| `entidad` | | Tabla o entidad afectada. |
| `entidad_id` | | Identificador del registro afectado. |
| `campo` | | Campo que cambió. |
| `valor_anterior` | | Valor antes del cambio. |
| `valor_nuevo` | | Valor después del cambio. |
| `usuario_id` | | Usuario que hizo el cambio. |
| `fecha` | | Fecha y hora del cambio. |

## Relaciones

| Tabla origen | Tabla destino | Cardinalidad | Campo de enlace |
|---|---|---|---|
| `usuarios` | `grupo_usuarios` | 1:* | `id_usuario` |
| `grupos` | `grupo_usuarios` | 1:* | `id_grupo` |
| `usuarios` | `usuario_etiquetas` | 1:* | `id_usuario`, `asignado_por` |
| `etiquetas` | `usuario_etiquetas` | 1:* | `id_etiqueta` |
| `usuarios` | `solicitudes` | 1:* | `id_solicitante`, `id_responsable` |
| `usuarios` | `modulos` | 1:* | `id_propietario`, `modificado_por` |
| `grupos` | `modulos` | 1:* | `id_grupo` |
| `modulos` | `sensores` | 1:* | `id_modulo` |
| `sensores` | `visualizacion` | 1:* | `id_sensor` |
| `usuarios` | `visualizacion` | 1:* | `id_usuario` |
| `usuarios` | `auditorias` | 1:* | `usuario_id` |

## Convenciones

| Abreviatura | Significado |
|---|---|
| **PK** | Clave primaria |
| **FK** | Clave foránea |
| **UK** | Clave única |
| **1:\*** | Uno a muchos |
| **1:1** | Uno a uno |
