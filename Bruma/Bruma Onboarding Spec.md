# Onboarding bruma. — Spec de diseño

> 4 pantallas · solo se muestra una vez tras registro exitoso · antes del dashboard

---

## Pantalla 1 — Bienvenida

**Propósito:** Establecer marca y promesa emocional. Romper la asociación "app financiera = ansiedad".

**Copy headline:**
Bienvenido a bruma.

**Copy subheadline:**
Tu dinero, sin ansiedad. Te ayudamos a entenderlo, no a culparte por él.

**Elemento visual:**
Composición central de **3 círculos concéntricos** que respiran (animación loop 4s, scale 1.0→1.04→1.0):
- Círculo exterior: 220px, `b.primary` con 8% opacidad, sin borde
- Círculo medio: 160px, `b.primary` con 14% opacidad
- Círculo interior: 96px, `b.primary` sólido, con el logo "b." centrado en 40sp w800 letterSpacing -4%, color blanco

La sensación es la de una niebla calmada disipándose hacia un centro claro — metáfora literal de la marca (bruma → claridad).

**Layout (stack vertical centrado, padding lateral 28px):**
- Top safe area + 80px → composición de círculos (220×220)
- Spacer 64px
- Headline en 28sp w700, color `b.textPrimary`, max 2 líneas, alineado izquierda
- Spacer 12px
- Subheadline en 16sp w400, color `b.textSecondary`, max 3 líneas, alineado izquierda, lineHeight 1.45
- Flex spacer (empuja al fondo)
- Indicador de progreso: 4 dots horizontales centrados (activo: `b.primary` 24×6 px píldora, inactivos: `b.border` 6×6 px circle, gap 6px)
- Spacer 24px
- Botón primario "Empezar" (52px alto, 14px radius, fondo `b.primary`, texto blanco 16sp w600)
- Spacer 8px
- Botón ghost "Saltar onboarding" (44px alto, fondo transparente, texto `b.textSecondary` 14sp w500, centrado)
- Bottom safe area + 16px

**Acción del usuario:** Tap en "Empezar" → avanza a Pantalla 2. Tap en "Saltar" → diálogo de confirmación, si confirma marca onboarding completado y va a dashboard.

**Dato capturado:** Ninguno.

---

## Pantalla 2 — Cómo funciona bruma.

**Propósito:** Comunicar el modelo mental de la app en una sola pantalla. Tres pilares, sin scroll.

**Copy headline:**
Tres cosas, ninguna complicada.

**Copy subheadline:**
Así te ayudamos a tener claridad sobre tu dinero.

**Elemento visual:**
Tres **filas de feature** apiladas verticalmente, cada una con:
- Cuadrito 48×48px de `b.primary` con 12% opacidad, radius 14px, contiene un **glifo SVG inline** monolínea (2px stroke, color `b.primary`):
  - Fila 1: glifo de **wallet** (rectángulo redondeado con solapa superior)
  - Fila 2: glifo de **dos flechas circulares** (refresh / sync)
  - Fila 3: glifo de **tres barras verticales** ascendentes (chart simple)
- A la derecha del cuadrito, columna de texto con título 16sp w600 + descripción 13sp w400 `b.textSecondary`, lineHeight 1.4

**Copy de cada fila:**
1. **Conecta o registra a mano**
   Empezamos con tu efectivo. Después conectas bancos cuando quieras.
2. **Cada gasto, una historia**
   Categoriza, anota, comenta. Tu yo del próximo mes te lo va a agradecer.
3. **Ve hacia dónde va**
   Sin juicios. Solo la verdad de a dónde se fue tu dinero esta semana.

**Layout (stack vertical, padding lateral 24px):**
- Top safe area + 64px
- Headline 26sp w700, alineado izquierda, color `b.textPrimary`
- Spacer 8px
- Subheadline 15sp w400 `b.textSecondary`
- Spacer 36px
- Las 3 filas, cada una de 64px alto, separadas por gap 20px (sin divider visible). Animación: cada fila aparece con FadeUp 300ms easeOut, delay escalonado 0ms / 80ms / 160ms.
- Flex spacer
- Dots de progreso (segundo activo)
- Spacer 24px
- Botón primario "Continuar"
- Spacer 8px
- Botón ghost "Saltar"
- Bottom safe area + 16px

**Acción del usuario:** Lee, hace tap en "Continuar".

**Dato capturado:** Ninguno.

---

## Pantalla 3 — Tu meta este mes

**Propósito:** Capturar el ÚNICO dato útil del onboarding — la meta de ahorro mensual del usuario. Esto activa la barra de progreso del dashboard desde el día uno y le da a la app un "para qué" personal.

**Copy headline:**
¿Cuánto te gustaría ahorrar este mes?

**Copy subheadline:**
Lo puedes cambiar cuando quieras. No es un compromiso, es una brújula.

**Elemento visual:**
Input grande tipo "número estrella" — el monto en sí es la pieza visual:
- Símbolo "$" en 32sp w400 color `b.textSecondary`, alineado al baseline
- Campo de número en **48sp w700 color `b.primary`**, letterSpacing -3%, fontVariantNumeric tabular-nums, alineado al centro horizontalmente
- Cursor titilante visible
- Debajo del monto, en 13sp w500 `b.textTertiary`: "MXN al mes"

Debajo del input, una **fila horizontal de 4 chips de sugerencia rápida** (con scroll horizontal si no caben):
- Chips: $1,000 · $3,000 · $5,000 · $10,000
- Estilo chip: 36px alto, 14px radius, padding horizontal 16px, fondo `b.surface`, borde 1px `b.border`, texto 14sp w500 `b.textPrimary`. Tap fija el monto en el input con animación de count-up de 400ms.

**Layout (stack vertical centrado):**
- Top safe area + 56px
- Botón "atrás" (chevron izquierdo 36×36 en `b.surface` con borde) en esquina superior izquierda
- Spacer 32px
- Headline 26sp w700, alineado izquierda, color `b.textPrimary`, padding lateral 24px
- Spacer 8px
- Subheadline 15sp w400 `b.textSecondary`, alineado izquierda
- Spacer 56px
- Bloque del input (centrado, padding vertical 24px)
- Spacer 28px
- Fila de chips de sugerencia (padding lateral 24px, gap 8px)
- Flex spacer
- Dots de progreso (tercero activo)
- Spacer 24px
- Botón primario "Guardar meta" (deshabilitado al 40% opacity si el monto es 0; al toque "exitoso" hace una micro-vibración háptica + checkmark animado dentro del botón antes de avanzar)
- Spacer 8px
- Botón ghost "Saltar"
- Bottom safe area + 16px

**Acción del usuario:** Toca un chip o teclea un monto, luego "Guardar meta".

**Dato capturado:** `monthly_savings_goal` (numeric, MXN). Persistencia:
- Tabla `user_settings` en Supabase: campo `monthly_savings_goal` numeric default 0
- Update por upsert con `tenant_id` del usuario
- En cliente: lo guarda también en SharedPreferences `monthly_goal` para acceso offline rápido

Si el usuario salta esta pantalla, el campo queda en NULL y el dashboard muestra el módulo de meta como "Define tu primera meta →" en lugar de la barra de progreso.

---

## Pantalla 4 — Listos

**Propósito:** Cerrar el onboarding con una sensación de logro y dejar al usuario emocionado de entrar al dashboard. Mostrar lo que ya está listo.

**Copy headline:**
Ya está. Vámonos.

**Copy subheadline:**
Creamos tu cuenta de efectivo automáticamente. Empieza por registrar tu primer gasto o ingreso del día.

**Elemento visual:**
**Checkmark animado** dentro de un círculo:
- Círculo de 96px, fondo `b.success` con 14% opacidad, sin borde
- Dentro, un círculo de 64px sólido `b.success`
- Encima del círculo sólido, un **path SVG de checkmark** (stroke 3.5px, color blanco, strokeLinecap round, strokeLinejoin round) que se dibuja con `stroke-dashoffset` animado de 0 a 100% en 600ms easeOutCubic al cargar la pantalla.

Debajo del checkmark, una **lista compacta de 3 ítems "ya listos"** con un puntito verde a la izquierda de cada uno:
- ✓ Cuenta de efectivo creada
- ✓ Categorías base configuradas
- ✓ Meta del mes registrada *(o "pendiente" en gris si la saltó)*

Cada ítem es 14sp w500, color `b.textPrimary`, con un dot 6×6 `b.success` 12px a la izquierda.

**Layout (stack vertical centrado, padding lateral 24px):**
- Top safe area + 80px
- Composición del checkmark animado (96×96 centrado horizontalmente)
- Spacer 32px
- Headline 28sp w700, **centrado horizontalmente**, color `b.textPrimary`, letterSpacing -3%
- Spacer 8px
- Subheadline 15sp w400 `b.textSecondary`, **centrada**, max 3 líneas, lineHeight 1.45
- Spacer 40px
- Lista de 3 ítems "ya listos" (alineados izquierda dentro de un contenedor centrado de ancho máx 280px)
- Flex spacer
- Dots de progreso (cuarto activo)
- Spacer 24px
- **Botón primario "Ir a mi dashboard"** (52px, único CTA, sin botón de saltar — esta pantalla ES el final)
- Bottom safe area + 16px

**Acción del usuario:** Tap en "Ir a mi dashboard". Marca onboarding como completado y navega.

**Dato capturado:** Ninguno. Marca `onboarding_completed = true` en SharedPreferences (y opcionalmente en `user_settings.onboarding_completed_at = NOW()` para analítica).

---

## Flujo de navegación

```
┌──────────────────────────────────────────────────────────┐
│  App startup → AuthGate                                  │
│                                                           │
│  ¿Hay sesión activa? ───No──▶ AuthScreen (login/register)│
│         │                                                 │
│        Sí                                                 │
│         ▼                                                 │
│  ¿SharedPreferences['onboarding_completed'] == true?     │
│         │                                                 │
│    ┌────┴────┐                                            │
│    No        Sí                                           │
│    │          │                                           │
│    ▼          ▼                                           │
│  Onboarding  DashboardScreen                              │
│    (1→2→3→4)                                              │
└──────────────────────────────────────────────────────────┘
```

### Detección en el router

En el `AuthGate`/router raíz, después de confirmar sesión:

```dart
final prefs = await SharedPreferences.getInstance();
final completed = prefs.getBool('onboarding_completed') ?? false;
return completed ? DashboardScreen() : OnboardingFlow();
```

### Marcado como completado

En **dos casos** se marca completado:
1. Usuario llega a Pantalla 4 y toca "Ir a mi dashboard"
2. Usuario toca "Saltar" en cualquier pantalla y confirma en el diálogo

```dart
await prefs.setBool('onboarding_completed', true);
// opcional para analítica:
await supabase.from('user_settings').upsert({
  'tenant_id': tenantId,
  'onboarding_completed_at': DateTime.now().toIso8601String(),
});
```

### Edge cases

**Usuario cierra la app a mitad del onboarding:**
- No se persiste el progreso intra-onboarding (no vale la pena la complejidad para 4 pantallas)
- Al reabrir, el flag sigue en `false`, así que el onboarding se reinicia desde Pantalla 1
- Esto es **deseable**: si cerró a mitad, probablemente no lo terminó de absorber

**Usuario salta y luego se arrepiente:**
- Hay entrada en Settings → "Ver tour de bienvenida" que reproduce las pantallas 2 y 4 (las informativas) sin tocar el flag
- La meta de ahorro (Pantalla 3) se puede crear normal desde el módulo de Presupuestos del dashboard

**Usuario reinstala la app:**
- SharedPreferences se borra → onboarding se vuelve a mostrar
- Si ya tiene `monthly_savings_goal` guardado en Supabase, la Pantalla 3 lo precarga como valor inicial del input (mejor experiencia que empezar en cero)

**Usuario cambia de dispositivo:**
- SharedPreferences es local; el flag NO se sincroniza
- Para que no vea el onboarding otra vez al cambiar de teléfono, en el primer login en un dispositivo nuevo el cliente lee `user_settings.onboarding_completed_at`. Si no es NULL, escribe `onboarding_completed = true` en SharedPreferences locales y va directo a dashboard.

---

## Sistema de animación del flujo

- **Transición entre pantallas:** slide horizontal de 280ms easeInOutCubic. Avance de derecha-a-izquierda, retroceso al revés.
- **Entrada de cada pantalla:** elementos hacen FadeUp con stagger 60ms entre headline → subheadline → elemento visual → CTA.
- **Tap del CTA:** scale 0.97 al press, vuelta a 1.0 al release (120ms). En la última pantalla añade un sutil ripple `b.primary` 8% que se expande desde el centro del botón antes de la transición al dashboard.

---

## Notas para implementación

- Las 4 pantallas comparten `OnboardingShell` que provee: padding consistente, dots de progreso, botón "Saltar" condicional, y el contenedor de animación de transición.
- Cada pantalla es un widget hijo que recibe `onNext()` y `onSkip()` callbacks — la shell maneja el state de la página actual y la persistencia.
- El input de Pantalla 3 debe usar `TextInputType.numberWithOptions(decimal: false)` y un formatter que añada comas de miles (`123,456` → leer como 123456).
- Los chips de Pantalla 3 deben tener feedback háptico ligero (`HapticFeedback.lightImpact()`) al tap.
