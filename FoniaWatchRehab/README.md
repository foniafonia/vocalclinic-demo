# FoniaWatch Rehab ⌚️🗣️

App de **Apple Watch (watchOS)** para **logopedia / rehabilitación cognitivo-lingüística**
tras **daño cerebral adquirido** (afasia, apraxia del habla, disartria, alteraciones de
lectura y escritura).

> ⚠️ **No diagnostica y no sustituye al logopeda.** Es una herramienta de **medición,
> biofeedback y registro** de la ejecución durante la sesión. La interpretación clínica
> es siempre del profesional.

---

## 1. Qué incluye este MVP

7 módulos accesibles desde la pantalla principal (botones grandes, texto grande, alto
contraste, modo infantil opcional con emojis):

| Módulo | Contenido | Medición / interacción |
|--------|-----------|------------------------|
| **Voz** | Tiempo máx. de fonación, repetir /a/, soplo | Micrófono real: círculo que crece con la voz, intensidad (dBFS), estabilidad, háptica al superar objetivo, aviso al detenerse |
| **Ritmo** | Sílabas (pa-ta-ka), frases a ritmo | Metrónomo visual + háptico por pulso, conteo de respuestas |
| **Afasia** | Denominación, comprensión, asociación semántica, fluidez verbal 30 s, repetición | El logopeda marca correcto/aproximación/error/no responde |
| **Lectura** | Sílabas, palabras, decisión léxica | Tiempo de respuesta + tipo de error (visual/fonológico/autocorrección/no lee) |
| **Escritura** | Copia, dictado, completar, ordenar letras | El logopeda marca omisión/sustitución/inversión/perseveración/ilegible/autocorrección |
| **Movimiento** | Inclinar para elegir, secuencia de gestos, respuesta a consigna | Acelerómetro/giroscopio (CoreMotion) |
| **Resultados** | Resumen + evolución 7 días | Sesiones, aciertos, errores, mejor fonación, resp./min; **reiniciar datos** |

**Persistencia:** local con `UserDefaults` (JSON `Codable`). Sin backend, sin login.

---

## 2. Estructura de carpetas

```
FoniaWatchRehab/
├── FoniaWatchRehab.xcodeproj/         # Proyecto Xcode (target único watchOS)
└── App/                              # Grupo sincronizado con el sistema de archivos
    ├── FoniaWatchRehabApp.swift       # @main
    ├── ContentView.swift             # Menú principal
    ├── Assets.xcassets/              # AppIcon + AccentColor
    ├── Models/
    │   ├── RehabModels.swift          # Enums + ExerciseRecord
    │   ├── SessionStore.swift         # Persistencia + resúmenes
    │   └── ContentData.swift          # Estímulos (palabras, sílabas, frases)
    ├── Managers/
    │   ├── HapticManager.swift        # Vibraciones
    │   ├── AudioLevelManager.swift    # Micrófono / nivel de voz
    │   └── MotionManager.swift        # Acelerómetro / giroscopio
    └── Views/
        ├── Components.swift           # Botones y tarjetas accesibles
        ├── VoiceView.swift            # Módulo 1
        ├── RhythmView.swift           # Módulo 2
        ├── AphasiaView.swift          # Módulo 3
        ├── ReadingView.swift          # Módulo 4
        ├── WritingView.swift          # Módulo 5
        ├── MovementView.swift         # Módulo 6
        ├── ResultsView.swift          # Módulo 7
        └── SettingsView.swift         # Ajustes (modo infantil, objetivos)
```

---

## 3. Cómo abrir en Xcode

Necesitas **Xcode 16 o superior** (macOS), porque el proyecto usa *grupos
sincronizados con el sistema de archivos* (objectVersion 77).

### Opción A — abrir el proyecto incluido (recomendada)
1. Descarga/clona el repo.
2. Doble clic en `FoniaWatchRehab/FoniaWatchRehab.xcodeproj`.
3. Xcode incluirá automáticamente todos los `.swift` de la carpeta `App/`.
4. Selecciona el esquema **FoniaWatch Rehab Watch App** y un simulador de Apple Watch.
5. Pulsa **▶︎ Run**.

### Opción B — recrear el proyecto a mano (si tu Xcode es antiguo)
1. **File ▸ New ▸ Project ▸ watchOS ▸ App**.
2. Product Name: `FoniaWatch Rehab`; Interface: **SwiftUI**; Language: **Swift**.
   Desmarca tests si quieres. (App independiente, sin app de iPhone.)
3. Borra el `ContentView.swift` que crea Xcode.
4. Arrastra a Xcode el **contenido** de la carpeta `App/` (todos los `.swift`, las
   carpetas `Models/`, `Managers/`, `Views/` y `Assets.xcassets`).
   Marca **Copy items if needed** y **Create groups**.
5. En el archivo `App.swift` deja **un solo** `@main` (usa el de este proyecto).

---

## 4. Permisos a activar

El proyecto ya declara los permisos vía *build settings* (`INFOPLIST_KEY_*`), así que
no hace falta editar Info.plist a mano. Si recreas el proyecto (Opción B), añade en la
pestaña **Info** del target:

| Clave | Valor |
|-------|-------|
| `Privacy - Microphone Usage Description` (`NSMicrophoneUsageDescription`) | *"FoniaWatch usa el micrófono para medir la voz (fonación e intensidad) como biofeedback."* |
| `Privacy - Motion Usage Description` (`NSMotionUsageDescription`) | *"FoniaWatch usa el sensor de movimiento para los ejercicios de respuesta con la muñeca."* |

La primera vez que entres en **Voz** o **Movimiento**, el reloj pedirá permiso. Hay que
**Permitir**.

---

## 5. Cómo probarlo en un Apple Watch real

1. Conecta el **iPhone emparejado** con el Apple Watch por cable al Mac (el reloj se
   instala a través del iPhone, o de forma inalámbrica si ya lo configuraste).
2. En Xcode: **Settings ▸ Accounts** → añade tu **Apple ID** (una cuenta gratuita de
   desarrollador sirve para probar en tu propio dispositivo).
3. Target **FoniaWatch Rehab Watch App ▸ Signing & Capabilities**:
   - Marca **Automatically manage signing**.
   - Elige tu **Team** (tu Apple ID).
   - Si el bundle id da conflicto, cámbialo por uno único, p. ej.
     `com.TUNOMBRE.foniawatchrehab.watchkitapp`.
4. En la barra superior, selecciona como destino **tu Apple Watch** (no el simulador).
5. Pulsa **▶︎ Run**. La primera vez:
   - En el **iPhone**: Ajustes ▸ General ▸ VPN y gestión de dispositivos → **confía**
     en tu certificado de desarrollador.
   - En el **Watch**: acepta instalar la app si lo pide.
6. La app queda instalada en el reloj. Ábrela desde la cuadrícula de apps.

> 💡 Si solo quieres ver que funciona sin reloj físico: elige un **simulador de Apple
> Watch** y pulsa Run. El micrófono y el movimiento funcionan mejor en el reloj real.

---

## 6. Limitaciones de esta primera versión

- **Intensidad vocal no calibrada:** el nivel se mide en **dBFS relativos** (no dB SPL).
  Sirve como biofeedback comparativo, no como sonómetro clínico. Hay un punto preparado
  (`IntensityCalibration`) para calibrar con el iPhone en la v2.
- **Sin reconocimiento de voz:** la app no transcribe ni juzga si la palabra es correcta;
  es el logopeda quien marca la ejecución (por diseño, para no "diagnosticar").
- **Persistencia básica:** `UserDefaults`. No hay exportación ni sincronización todavía.
- **Estímulos fijos** en `ContentData.swift` (editables en código, aún no desde la app).
- **Sin perfiles de paciente:** los datos son globales del dispositivo.
- **Gestos de movimiento** simplificados (umbrales fijos de inclinación).

---

## 7. Qué mejorar en la segunda versión

- App **complementaria de iPhone** (WatchConnectivity) para: calibrar intensidad real,
  ver informes grandes y **exportar a PDF/CSV**.
- **Perfiles de paciente** y selección de sesión.
- **SwiftData / CloudKit** para historial robusto y sincronizado.
- **Reconocimiento de voz** opcional (Speech framework en iPhone) para apoyo, sin que
  sustituya el criterio clínico.
- **Editor de estímulos** desde la propia app (que el logopeda cree sus listas).
- **HealthKit** (frecuencia cardiaca) como medida de esfuerzo/fatiga durante la sesión.
- **Informes de evolución** más ricos (por módulo, por tipo de error).
- Localización (es/en/…) y revisión de accesibilidad con VoiceOver.

---

**Autor del proyecto clínico:** José Aserraf — Logopeda
**Estado:** MVP funcional v1.0 · watchOS 10+
