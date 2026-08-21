# Ritmo

App nativa AppKit para macOS que distribuye un saldo mensual entre los días hábiles y muestra cuánto corresponde haber usado hasta una fecha determinada.

## Descargar

Descargá el ZIP de la [última versión](https://github.com/GHDominguez/ritmo/releases/latest), descomprimilo y mové `Ritmo.app` a la carpeta Aplicaciones.

Ritmo no está firmado con un certificado de Apple. La primera vez que lo abras, macOS puede bloquearlo:

1. Intentá abrir `Ritmo.app` una vez.
2. Abrí **Configuración del Sistema → Privacidad y seguridad**.
3. Buscá el aviso sobre Ritmo y elegí **Abrir de todos modos**.

El ZIP incluye una aplicación universal compatible con Macs Apple Silicon e Intel. Requiere macOS 14 o posterior.

## Compilar y abrir

Requiere macOS 14 o posterior y las Command Line Tools de Apple.

```bash
./scripts/build-app.sh
open dist/Ritmo.app
```

El bundle local queda en `dist/Ritmo.app`. Usa una firma ad-hoc, sin certificado de Apple.

Mientras está ejecutándose, la barra de menú muestra el límite acumulado del día. Un clic sobre el importe abre u oculta la ventana; cerrar la ventana mantiene el indicador activo. Para salir por completo, usá **Ritmo → Salir de Ritmo** o `⌘Q`.

La fecha avanza automáticamente al cambiar el día, también si la app queda abierta durante la noche. Ritmo vuelve a comprobarla cada minuto y al regresar a la aplicación.

Para ejecutar las pruebas del cálculo sin Xcode:

```bash
./scripts/test-core.sh
```

El código de la aplicación está en `Native/` y no requiere un proyecto de Xcode.

## Publicar una versión

Los tags cuyo nombre comienza con `v` crean una versión en GitHub Releases. Por ejemplo:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions ejecuta las pruebas, compila la aplicación universal y adjunta el ZIP a la versión.

## Criterio de cálculo

- Cuenta lunes a viernes del mes de la fecha seleccionada.
- Resta los feriados nacionales argentinos previsibles incluidos y los días no laborables agregados manualmente.
- Divide el saldo por el total de jornadas hábiles.
- Multiplica ese valor por las jornadas transcurridas hasta hoy, incluyendo hoy si es hábil.

El saldo y las excepciones se guardan en las preferencias de la app.
