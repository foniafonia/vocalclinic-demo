# NeuroTrack Watch — MVP

Herramienta de observación digital y registro objetivo de patrones motores repetitivos.
**No diagnóstica. No mide gravedad. Complementa la valoración profesional.**

---

## Qué hace

- Captura acelerómetro y giroscopio del Apple Watch a 50 Hz.
- Detecta episodios de movimiento repetitivo de miembro superior (1–4.5 Hz, duración ≥ 1.5 s).
- Envía cada episodio al iPhone companion vía WatchConnectivity.
- Muestra lista de episodios por día con duración, intensidad y frecuencia dominante.
- Permite validación manual por adulto/terapeuta: pendiente / validado / falso positivo.
- Exporta datos en JSON y CSV.

## Qué NO hace

- No diagnostica autismo ni ninguna condición.
- No mide "gravedad" ni "nivel" de ninguna condición.
- No detecta gestos con la cara, ojos ni dedos.
- No sustituye valoración clínica.

---

## Estructura del proyecto

```
NeuroTrackWatch/
├── Shared/Models/             ← DetectedEvent, MotionSample, SessionRecord
├── WatchApp/
│   ├── App/                   ← @main entry
│   ├── Sensors/               ← SensorManager (CoreMotion wrapper)
│   ├── Detection/             ← MotionBuffer, FeatureExtractor, HeuristicDetector
│   ├── Storage/               ← WatchEventStore (JSON queue)
│   ├── Connectivity/          ← WatchConnectivityManager
│   └── Views/                 ← SessionView, SessionViewModel
└── iOSApp/
    ├── App/                   ← @main entry
    ├── Storage/               ← EventStore (JSON, observable)
    ├── Connectivity/          ← PhoneConnectivityManager
    └── Views/                 ← MainTabView, EventListView, EventDetailView, DailySummaryView
```

---

## Setup en Xcode

### Requisitos

- Xcode 16+
- iOS 17+ deployment target
- watchOS 10+ deployment target
- Apple Developer account (para WatchConnectivity en dispositivo real)

### Pasos

1. **Crea el proyecto Xcode**
   - File → New → Project → iOS App
   - Product name: `NeuroTrackWatch`
   - Bundle ID: `com.tuempresa.neurotrackwatch`
   - Marca "Include Tests" si quieres

2. **Añade el Watch App target**
   - File → New → Target → watchOS → Watch App
   - Product name: `NeuroTrack Watch`
   - Asegúrate de que el Bundle ID sea `com.tuempresa.neurotrackwatch.watchkitapp`
   - Desmarca "Include Notification Scene" (no necesario en MVP)

3. **Añade los archivos fuente**
   - Arrastra `Shared/` a ambos targets (iOS + watchOS) — son modelos compartidos
   - Arrastra `WatchApp/` solo al target watchOS
   - Arrastra `iOSApp/` solo al target iOS
   - Verifica que cada archivo tenga el target membership correcto en el inspector

4. **Frameworks**
   - watchOS target → Frameworks: `CoreMotion.framework`, `WatchConnectivity.framework`
   - iOS target → Frameworks: `WatchConnectivity.framework`
   - iOS target → Capabilities: añade Charts (viene incluido en SwiftUI, no es librería externa)

5. **Info.plist — permisos**
   - watchOS Info.plist:
     ```
     NSMotionUsageDescription = "NeuroTrack necesita el acelerómetro para detectar patrones de movimiento."
     ```

6. **App Groups (opcional, para compartir datos directamente)**
   - Capabilities → App Groups → añade `group.com.tuempresa.neurotrackwatch`
   - En `WatchEventStore` y `EventStore`, cambia `FileManager.default.urls(for: .documentDirectory, ...)` por el App Group container si quieres acceso cruzado al sistema de archivos (no necesario en MVP porque WatchConnectivity cubre la sincronización).

7. **Sesiones largas en watchOS**
   Para que la detección funcione con la pantalla apagada o en segundo plano,
   añade una `WKExtendedRuntimeSession` de tipo `.workout` al iniciar la sesión.
   El MVP no la incluye para mantenerlo simple; sin ella el muestreo puede
   reducirse a ~1 Hz tras 15 segundos con la muñeca baja.

---

## Detector heurístico — parámetros

Todos los umbrales están en `DetectorThresholds` y se persisten en `UserDefaults`.

| Parámetro | Valor por defecto | Descripción |
|---|---|---|
| `minRMS` | 0.15 g | Intensidad mínima del movimiento |
| `minVariance` | 0.015 | Varianza mínima — filtra sweeps lentos |
| `minRhythmicity` | 0.28 | Autocorrelación normalizada — periodicidad |
| `minFrequencyHz` | 1.0 Hz | Límite inferior de la banda de estereotipia |
| `maxFrequencyHz` | 4.5 Hz | Límite superior |
| `minConsecutiveWindows` | 3 | Ventanas activas mínimas para abrir episodio |
| `gapToleranceWindows` | 2 | Ventanas silenciosas toleradas dentro de episodio |

Para aumentar la especificidad (menos falsos positivos): subir `minRhythmicity` a 0.35–0.40.
Para aumentar la sensibilidad: bajar `minRMS` a 0.10 y `minRhythmicity` a 0.22.

---

## Evolución hacia modelo personalizado (roadmap)

1. **Fase actual (MVP):** reglas heurísticas con umbrales fijos.
2. **Fase 2 — calibración por usuario:** permitir al terapeuta grabar ejemplos etiquetados
   (positivos/negativos). Ajustar los umbrales por regresión sobre las features.
3. **Fase 3 — modelo ligero embebido:** entrenar un clasificador binario simple
   (SVM o árbol de decisión) con las features de cada ventana. Exportar con
   Core ML y ejecutarlo en el Watch con `MLModel.prediction(from:)`.
4. **Fase 4 — personalización continua:** el modelo re-entrena periódicamente
   en el iPhone con los datos validados del usuario, y se actualiza en el Watch
   via `WCSession.transferFile`.

---

## Limitaciones conocidas

- **Background con pantalla apagada:** sin `WKExtendedRuntimeSession`, watchOS
  reduce el muestreo. Para monitoreo continuo en segundo plano, implementar
  una Workout Session (requiere permiso HealthKit adicional).
- **Falsos positivos con gestos cotidianos:** aplaudir, lavar manos, agitar un
  objeto puede activar el detector. La validación manual es la principal
  salvaguarda en esta fase.
- **Frecuencia de autocorrelación:** el cálculo es O(n²) por ventana — tolerable
  a 100 muestras/ventana pero hay que reemplazarlo por FFT si se aumenta la
  frecuencia de muestreo o el tamaño de ventana.
- **Sin diagnóstico:** los valores de RMS, ritmicidad y frecuencia son
  indicadores de actividad motora, no biomarcadores clínicos validados.
