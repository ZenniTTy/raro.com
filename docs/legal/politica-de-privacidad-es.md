# Política de privacidad — Raro Camera

Última actualización: 4 de septiembre de 2026.

Este texto describe lo que hace la aplicación **Raro Camera** (iOS y Android, identificador `com.rarocamera`) con los datos. No es asesoramiento jurídico.

## 1. Quién trata los datos

El responsable de los datos personales es:

**Vitor Autorino Lopes (Raro Camera)**

Para ejercer derechos o preguntar: **rarocan1@gmail.com**.

Versión pública de este texto: [https://rarocamera.com.br/es/privacidad](https://rarocamera.com.br/es/privacidad).

No pedimos registro, inicio de sesión, nombre ni correo dentro de la app. No operamos un servidor propio (no hay API ni nube de vídeo nuestra).

Estas páginas del sitio son archivos estáticos. **No usamos cookies ni analítica en este sitio.**

## 2. Resumen

Raro Camera graba vídeo en el aparato, con un comando de voz opcional (“Raro gravar” / “Raro parar”) y un búfer de replay local. Los archivos se quedan en el aparato. Lo que sale del aparato, sin una acción tuya de exportar o compartir, es solo telemetría de uso, informe de fallos y — si te suscribes — el recibo de la tienda tratado por RevenueCat y la App Store o Google Play.

## 3. Lo que no pedimos y no enviamos

La app **no**:

- crea cuenta, perfil ni contraseña;
- pide correo, teléfono, CPF ni dirección;
- lee tus contactos, calendario o ubicación;
- lee el carrete (en iOS solo **añade** un vídeo cuando eliges guardar);
- envía el archivo de vídeo o el audio de la grabación hacia nosotros;
- envía la transcripción de tu voz hacia nosotros o a un servidor nuestro;
- muestra anuncios de terceros.

## 4. Lo que se queda solo en el aparato

### 4.1 Vídeo, audio y miniatura

Los clips (MP4), el audio incrustado, la miniatura y un archivo al lado (duración, fecha, resolución, fps, lente, si vino del replay) se quedan en el espacio privado de la app.

No hay copia automática en la nube. No hay sincronización entre un iPhone y un Android. Si borras la app, ese acervo del sandbox desaparece con ella.

Guardar el clip de forma permanente (bóveda de la app + carpeta de la galería del sistema) y compartirlo exigen suscripción activa. Sin suscripción puedes grabar y ver el resultado en la pantalla de vista previa; rechazar la suscripción descarta el archivo temporal de esa grabación. Los vídeos que ya estaban en la bóveda siguen en el aparato.

Borrar un clip en la app lo quita de la bóveda. **No** quita una copia que ya hayas exportado a Fotos / la galería de Android.

### 4.2 Preferencias

En el almacenamiento local del sistema la app guarda solo lo que necesita para funcionar: si el onboarding ya pasó, idioma, resolución, fps, duración del búfer, modo de control, si el aviso Xiaomi ya apareció, fecha de la primera apertura y una caché local del estado de la suscripción. Eso no es un registro.

### 4.3 Voz

El reconocimiento de voz corre **en el aparato**:

- **Android:** motor Vosk, en el propio teléfono, incluso en segundo plano mediante un servicio en primer plano de tipo micrófono.
- **iOS:** reconocimiento de habla con procesamiento **obligatoriamente en el aparato**.

El audio de la voz **no se envía** a un servidor nuestro. Los registros técnicos de la app anotan solo si el comando reconocido fue iniciar o parar la grabación — **no** graban el texto hablado.

Puedes rechazar el micrófono. Sin micrófono no hay comando de voz ni audio en el clip; la cámara de vídeo aún puede usarse si la permiso de cámara está concedido.

## 5. Lo que sale del aparato

### 5.1 Firebase Analytics (Google)

Usamos Firebase Analytics para saber si la app se abre, si la cámara arranca y si hubo un error de cámara.

En esta versión, los eventos personalizados que dispara nuestro código son:

- `camera_started` — lente, resolución y fps activos;
- `camera_error` — código del error y, si hay, el mensaje técnico.

El producto tiene una lista mayor de nombres de evento previstos (por ejemplo apertura, paywall, plan elegido, cambio de lente). Esos nombres existen en el código; la mayoría aún no se envía. El propio SDK de Firebase también registra eventos automáticos (primera apertura, sesión, actualización de la app).

No asociamos esos eventos a un correo ni a un nombre. No enviamos vídeo ni habla.

El SDK de Firebase, si no se desactiva aparte, puede recoger identificadores del aparato y, en Android, el identificador de publicidad. Raro Camera **no** usa ese identificador para anuncios. No pedimos el permiso de tracking de Apple (ATT). Hoy **no hay** un interruptor de Analytics dentro de la app.

Política de Google: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.2 Firebase Crashlytics (Google)

Si la app se cierra o lanza un error no tratado, Crashlytics recibe el rastreo del fallo, la versión de la app y los datos de aparato/sistema que el SDK incluye por defecto. Sirven para reparar la app. No adjuntamos tu nombre ni tu correo.

### 5.3 Suscripción — RevenueCat, Apple y Google

No procesamos tarjeta. La compra pasa por la **App Store** (iOS) o **Google Play** (Android).

RevenueCat recibe un identificador anónimo de usuario del SDK (no iniciamos sesión) y el recibo que emite la tienda, para saber si el beneficio premium está activo y hasta cuándo. Sirve para liberar guardar y compartir, y para el botón “Restaurar compras”.

Quien cobra, guarda el medio de pago y te autentica es Apple o Google, con la cuenta que ya tienes en el teléfono. No hay suscripción compartida automática entre iPhone y Android: son tiendas distintas.

- RevenueCat: [https://www.revenuecat.com/privacy](https://www.revenuecat.com/privacy)
- Apple: [https://www.apple.com/legal/privacy/](https://www.apple.com/legal/privacy/)
- Google Play: [https://policies.google.com/privacy](https://policies.google.com/privacy)

### 5.4 Exportar y compartir (tú eliges)

Si tienes suscripción y pulsas guardar, la app escribe el MP4 en la galería del sistema (en iOS, solo añade; en Android, carpeta `Movies/Raro Camera/`). A partir de ahí el archivo también vive bajo las reglas de la galería del aparato.

Si pulsas compartir, el sistema abre la hoja nativa. El destino (WhatsApp, Files, AirDrop, etc.) es tu elección. Ese destino deja de ser tratamiento nuestro.

### 5.5 Internet

La app pide red para Analytics, Crashlytics y suscripción. Grabar y ver clips ya guardados en la bóveda **no** exige internet.

## 6. Permisos del sistema

| Permiso | Para qué | ¿Se puede rechazar? |
|---|---|---|
| Cámara | Vista previa y grabación | Sí. Sin cámara la app no graba vídeo |
| Micrófono | Audio del clip y comando de voz | Sí. Sin micrófono no hay voz ni sonido en el vídeo |
| Reconocimiento de habla (iOS) | Entender “Raro gravar” / “Raro parar” en el aparato | Sí. Sin eso el comando de voz en iOS no funciona |
| Añadir a la galería (iOS) / almacenamiento legado (Android 9 e inferior) | Solo cuando pides guardar el clip | Sí. El clip puede quedarse solo en la bóveda de la app (si la suscripción permite persistir) |
| Notificaciones (Android) | Aviso del servicio de micrófono en segundo plano | Sí. El sistema puede limitar el servicio en segundo plano |
| Servicio en primer plano / micrófono (Android) | Mantener la escucha de voz con la app en segundo plano | Sin eso la voz en background en Android no arranca |
| Internet | Analytics, fallos, suscripción | Sin red, esas partes quedan mudas; la cámara local sigue |

Ninguno de estos permisos se usa para leer tu carrete ni para rastrear anuncios.

## 7. Finalidades

Tratamos lo mínimo que la app necesita para:

- ejecutar lo que pediste (grabar, guardar, compartir, suscribirte, restaurar una compra);
- mejorar estabilidad y uso (Analytics y Crashlytics, sin el contenido de la cámara);
- cumplir la regla de las tiendas y la ley (recibo de suscripción, atender tu petición).

No vendemos datos. No tomamos una decisión automatizada con efecto jurídico más allá de “tiene o no el beneficio premium”, y eso viene del recibo de la tienda.

## 8. Tus derechos

Puedes pedir, a **rarocan1@gmail.com**, confirmación del tratamiento, acceso, corrección, anonimización, portabilidad cuando corresponda, información sobre cesiones y revocación de los permisos del sistema (esos también se revocan en Ajustes de iOS / Ajustes de Android).

Caminos prácticos, sin esperar el correo:

- **Vídeos en la bóveda:** bórralos en la propia app o desinstala la app.
- **Copia en la galería del sistema:** bórrala en Fotos / Galería — Raro Camera no la toca al borrar.
- **Permisos:** ajustes del aparato.
- **Suscripción:** cancela en la App Store o en Google Play; RevenueCat deja de ver un recibo activo.
- **Identificador anónimo de RevenueCat / datos de fallos y analítica:** pídelo al correo de arriba. No tenemos un registro tuyo; la petición se reenviará al encargado en lo que se pueda identificar.

Si estás en Brasil, la ANPD es la autoridad de control.

## 9. Cuánto tiempo se guarda

| Dato | Conservación |
|---|---|
| Clip y sidecar en la bóveda | Hasta que lo borres o desinstales la app |
| Copia en la galería del sistema | Hasta que la borres en la galería; no sigue el borrado de la app |
| Preferencias locales | Hasta borrar datos de la app o desinstalar |
| Eventos de Analytics / fallos | Plazo por defecto de los paneles Firebase del proyecto |
| Recibo / entitlement en RevenueCat | Mientras la tienda y RevenueCat mantengan el historial de ese identificador anónimo |

## 10. Transferencia fuera de Brasil

Google (Firebase) y RevenueCat tratan datos fuera de Brasil, en general en Estados Unidos, bajo sus contratos con quien publica la app. No alojamos vídeo nuestro en otro país porque **no alojamos vídeo**.

## 11. Niños

La app no pide edad y no tiene área infantil. No está hecha para niños. Si eres responsable de un menor y quieres que borremos lo que se pueda identificar en los encargados, escribe a **rarocan1@gmail.com**.

La clasificación por edad de las tiendas se define en App Store Connect y Play Console al publicar.

## 12. Cambios

Si la app empieza a recoger algo nuevo (inicio de sesión, nube, otro SDK), esta política debe reescribirse **antes** de ese cambio. La fecha de arriba cambia. La URL canónica sigue apuntando al texto vigente.

## 13. Contacto

Vitor Autorino Lopes (Raro Camera)  
Correo: rarocan1@gmail.com  
Documento: [https://rarocamera.com.br/es/privacidad](https://rarocamera.com.br/es/privacidad)
