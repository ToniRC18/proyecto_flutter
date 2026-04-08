# Bruma 💰

### Aplicación móvil de salud financiera personal y colaborativa

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-%233ECF8E.svg?style=flat&logo=Supabase&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-%23FFCA28.svg?style=flat&logo=Firebase&logoColor=black)
![Riverpod](https://img.shields.io/badge/Riverpod-%23000000.svg?style=flat)
![GoRouter](https://img.shields.io/badge/GoRouter-%230175C2.svg?style=flat)

---

## 📝 Descripción General

**Bruma** es una aplicación móvil desarrollada con Flutter que permite a los usuarios gestionar sus finanzas personales y compartidas de manera intuitiva y visualmente atractiva. 

Este proyecto fue desarrollado como parte de la materia de **Desarrollo de Aplicaciones Móviles**, con el objetivo de aplicar conocimientos avanzados en integración de backends modernos (BaaS), manejo de estado reactivo y comunicación en tiempo real.

---

## ✨ Características Implementadas

### 🔐 Autenticación
*   **Seguridad:** Registro e inicio de sesión seguro con email y contraseña.
*   **Persistencia:** Gestión de sesión persistente mediante tokens JWT.
*   **Protección de Rutas:** Redirección automática basada en el estado de autenticación (integración GoRouter + Riverpod).
*   **Automatización:** Creación automática de un espacio personal (tenant) y una cuenta de efectivo inicial al momento del registro mediante triggers en PostgreSQL.

### 💳 Gestión de Cuentas (RF-05)
*   **Tipos de Cuenta:** Creación y edición de cuentas de tipo Cash (Efectivo), Bank (Banco) y Credit Card (Tarjeta de crédito).
*   **Resumen:** Visualización del balance total consolidado de todas las cuentas.
*   **Historial:** Seguimiento detallado de transacciones recientes específicas por cada cuenta.

### 💸 Transacciones (RF-06, RF-07)
*   **Gastos:** Registro rápido de egresos indicando categoría, cuenta de origen y fecha.
*   **Ingresos:** Registro de entradas de dinero con categorías personalizadas.
*   **UX Ágil:** Teclado numérico personalizado diseñado para una entrada de datos veloz.
*   **Categorización:** Selector radial de categorías activable mediante pulsación larga para una mejor experiencia de usuario.

### 🤝 Comunicación y Características Colaborativas (Unidad 3 — Redes Sociales)
Esta sección destaca las funcionalidades sociales y de colaboración en tiempo real del proyecto (RF-04, RF-09, RF-10):

*   **Espacios Compartidos:** Capacidad de crear entornos financieros conjuntos (tenants shared) para parejas, roomies o grupos de amigos.
*   **Gestión de Invitaciones:** Sistema para invitar a otros usuarios mediante correo electrónico, permitiéndoles aceptar o rechazar la colaboración desde la app.
*   **Balance del Grupo:** Visualización clara de quién ha gastado más y quién debe a quién dentro de un espacio compartido.
*   **Interacción Social:** Sistema de **comentarios en tiempo real** en cada transacción utilizando WebSockets (Supabase Realtime), funcionando como un canal de mensajería contextual.
*   **Notificaciones Push (FCM):**
    *   Alertas instantáneas cuando un miembro del grupo registra un nuevo gasto.
    *   Notificaciones al recibir una invitación a un nuevo espacio compartido.
    *   Manejo robusto de notificaciones en estados: Foreground (primer plano), Background (segundo plano) y Terminated (app cerrada).
*   **Transparencia:** Identificación clara de qué miembro registró cada movimiento dentro del historial grupal.
*   **Roles:** Gestión de permisos básicos (Dueño vs Miembro).

> [!IMPORTANT]
> Estas características implementan una comunicación bidireccional entre usuarios en tiempo real, cumpliendo con los requisitos de la unidad de **Comunicación y Redes Sociales en Aplicaciones Móviles**.

### 🎯 Presupuestos (RF-13, RF-14)
*   **Límites de Gasto:** Definición de montos máximos por categoría (ej. Comida, Ocio, Renta).
*   **Visualización:** Barras de progreso dinámicas con códigos de color basados en el porcentaje consumido.
*   **Análisis:** Comparación en tiempo real del gasto acumulado vs. el presupuesto asignado para el mes en curso.
*   **Flexibilidad:** Soporte para períodos presupuestarios mensuales y semanales.

### ⏳ Próximas Implementaciones
*   **RF-11/12:** Gestión avanzada de pagos recurrentes y recordatorios inteligentes.
*   **RF-08:** Transferencias internas entre cuentas con registro automático.

---

## 🛠️ Stack Tecnológico

| Tecnología | Uso |
| :--- | :--- |
| **Flutter** | Framework principal para desarrollo multiplataforma (iOS y Android). |
| **Supabase** | Backend as a Service (PostgreSQL, Auth, REST API y Realtime). |
| **Firebase Cloud Messaging** | Infraestructura para el envío de notificaciones push. |
| **Riverpod** | Motor de gestión de estado reactivo y predecible. |
| **GoRouter** | Navegación declarativa y manejo de rutas profundas. |
| **PostgreSQL** | Base de datos relacional con Row Level Security (RLS). |

---

## 🏛️ Arquitectura del Proyecto

El proyecto sigue una arquitectura **Feature-first** combinada con el **Repository Pattern**, garantizando escalabilidad y facilidad de prueba.

### Estructura de Carpetas
```text
lib/
 ├── core/
 │    ├── notifications/   → Configuración de FCM y notificaciones locales.
 │    ├── router/          → Definición de rutas con guardias de seguridad.
 │    ├── supabase/        → Cliente centralizado de Supabase.
 │    ├── theme/           → Sistema de diseño (colores, fuentes).
 │    ├── widgets/         → Componentes globales (navbar, glass cards).
 └── features/
      ├── auth/            → Lógica de ingreso, registro y perfiles.
      ├── dashboard/       → Resumen financiero y vista principal.
      ├── accounts/        → Gestión de carteras y saldos.
      ├── transactions/    → Registro y detalle de movimientos.
      ├── budget/          → Control de presupuestos por categoría.
      ├── shared_spaces/   → Colaboración, invitaciones y balances sociales.
      ├── profile/         → Configuración de usuario y cierre de sesión.
```

---

## 🗄️ Modelo de Datos y Seguridad

### Esquema de la Base de Datos
```text
profiles → tenant_members → tenants
                               ↓
                           accounts → transactions
                               ↓
                            budgets
                               ↓
                    transaction_comments (Realtime)
                    tenant_invitations
                    push_tokens
```

| Tabla | Descripción |
| :--- | :--- |
| **profiles** | Información extendida de los usuarios. |
| **tenants** | Entidades de "espacio" (Personal o Compartido). |
| **tenant_members** | Relación muchos a muchos entre usuarios y espacios. |
| **accounts** | Carteras financieras dentro de un espacio. |
| **transactions** | Registros de gastos e ingresos. |
| **budgets** | Metas de ahorro y límites de gasto. |
| **transaction_comments** | Mensajería social ligada a transacciones. |
| **tenant_invitations** | Gestión de acceso a espacios colaborativos. |
| **push_tokens** | Registro de dispositivos para notificaciones FCM. |

> [!TIP]
> **Seguridad:** Se utiliza **Row Level Security (RLS)** en todas las tablas para garantizar que un usuario solo pueda leer o escribir datos pertenecientes a sus propios espacios (tenants).

---

## 🎨 Diseño UI/UX

*   **Paleta de Colores:** Estética moderna basada en **Lemon Chiffon (#FEFACD)** y **Ultra Violet (#5F4A8B)**.
*   **Estilo Visual:** **Glassmorphism** premium con efectos de `BackdropFilter` (blur de 14px) y bordes sutiles.
*   **Tipografía:** Poppins para una lectura clara y moderna.
*   **Filosofía:** "Dinero sin ansiedad" — un diseño limpio que evita colores agresivos, promoviendo una gestión calmada de las finanzas.
*   **Navegación:** Barra inferior personalizada con un botón "+" elevado central para acciones rápidas.

---

## 🚀 Instalación y Configuración

Siga estos pasos para ejecutar el proyecto localmente:

1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/ToniRC18/proyecto_flutter.git
    cd proyecto_con_mi_compa
    ```

2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```

3.  **Configurar Firebase (Obligatorio para notificaciones):**
    ```bash
    dart pub global activate flutterfire_cli
    flutterfire configure
    ```

4.  **Ejecutar la aplicación:**
    ```bash
    flutter run
    ```

### Requisitos Previos:
*   Flutter SDK >= 3.x
*   Proyecto en Supabase con el esquema de tablas configurado.
*   Proyecto en Firebase con Cloud Messaging habilitado.
*   iOS: `GoogleService-Info.plist` en `ios/Runner/`.
*   Android: `google-services.json` en `android/app/`.

---

## ✅ Requisitos Funcionales Implementados

| RF | Descripción | Estado |
| :--- | :--- | :---: |
| **RF-01** | Registro de usuario | ✅ |
| **RF-02** | Login + Persistencia de sesión | ✅ |
| **RF-03** | Creación automática de espacio personal | ✅ |
| **RF-04** | Espacios compartidos + Sistema de invitaciones | ✅ |
| **RF-05** | Gestión multicuenta (Cash, Bank, CC) | ✅ |
| **RF-06** | Registro de gastos con fecha y categoría | ✅ |
| **RF-07** | Registro de ingresos | ✅ |
| **RF-08** | Transferencias entre cuentas | ⏳ |
| **RF-09** | División de gastos (Split bill) | ✅ |
| **RF-10** | Balance consolidado entre usuarios | ✅ |
| **RF-11** | Registro de gastos recurrentes | ⏳ |
| **RF-12** | Recordatorios de fecha de corte/pago | ⏳ |
| **RF-13** | Definición de presupuestos por categoría | ✅ |
| **RF-14** | Comparación gráfica Gasto vs Presupuesto | ✅ |

---

## 👥 Autores

*   **Universidad de Monterrey (UDEM)**
*   **Materia:** Desarrollo de Aplicaciones Móviles
*   **Desarrollado por:** [Toni Rosas Castillo](https://github.com/ToniRC18) y [Nombre del Compañero]
*   **Semestre:** Primavera 2026

---
© 2026 Bruma - Finanzas con menos estrés.
