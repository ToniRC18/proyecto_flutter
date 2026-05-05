// ─── BRUMA — Pantallas adicionales ─────────────────────────────────────────
// Login, Stats/Budget, Shared Spaces, Space Detail, Transaction Detail, Transfer
// Todas siguen el design system existente. Tokens vienen como prop.

const { useState: useStateX, useEffect: useEffectX } = React;

// ══ DATOS DE MUESTRA ══════════════════════════════════════════════════════
const SAMPLE_BUDGETS = [
  { id: 1, name: 'Comida', spent: 1840, total: 3000, category: 'food' },
  { id: 2, name: 'Transporte', spent: 420, total: 800, category: 'transport' },
  { id: 3, name: 'Entretenimiento', spent: 980, total: 800, category: 'shopping' },
];

const CATEGORY_BREAKDOWN = [
  { category: 'food', label: 'Comida', pct: 38, amount: 2440 },
  { category: 'transport', label: 'Transporte', pct: 22, amount: 1413 },
  { category: 'shopping', label: 'Compras', pct: 18, amount: 1156 },
  { category: 'health', label: 'Salud', pct: 12, amount: 770 },
  { category: 'other', label: 'Otros', pct: 10, amount: 642 },
];

const SAMPLE_SPACES = [
  { id: 1, name: 'Depa Cumbres', members: [
    { name: 'Antonio', color: '#0066FF' },
    { name: 'Carlos', color: '#00A878' },
    { name: 'Ana', color: '#F59E0B' },
  ], userBalance: 450, status: 'Activo' },
  { id: 2, name: 'Viaje CDMX', members: [
    { name: 'Antonio', color: '#0066FF' },
    { name: 'Sofía', color: '#9333EA' },
    { name: 'Mario', color: '#FF6B35' },
    { name: 'Lucía', color: '#00D4AA' },
    { name: 'Diego', color: '#EC4899' },
  ], userBalance: -1200, status: 'Activo' },
  { id: 3, name: 'Gastos con Toni', members: [
    { name: 'Antonio', color: '#0066FF' },
    { name: 'Toni', color: '#FF6B35' },
  ], userBalance: 0, status: 'Activo' },
];

const SPACE_TXS = [
  { id: 1, title: 'Renta abril', category: 'home', amount: -8400, date: 'Hace 2 días', payer: 'Carlos' },
  { id: 2, title: 'Súper Costco', category: 'food', amount: -1850, date: 'Hace 4 días', payer: 'Tú' },
  { id: 3, title: 'Internet Totalplay', category: 'home', amount: -699, date: 'Hace 1 sem', payer: 'Ana' },
  { id: 4, title: 'Pizza fin de semana', category: 'food', amount: -560, date: 'Hace 1 sem', payer: 'Tú' },
];

const SAMPLE_COMMENTS = [
  { id: 1, name: 'Carlos', initial: 'C', color: '#00A878', text: '¿Es de la fiesta del sábado?', time: '14:25' },
  { id: 2, name: 'Tú', initial: 'A', color: '#0066FF', text: 'No, fue el lunch de hoy 🍔', time: '14:30' },
];

// ══ HELPERS UI ══════════════════════════════════════════════════════════════
function Divider({ tokens, margin = '0 16px' }) {
  return <div style={{ height: 1, background: tokens.border, margin }} />;
}

function ScreenHeader({ tokens, title, onBack, rightIcon, rightAction }) {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '16px 20px 0',
      marginBottom: 20,
    }}>
      {onBack ? (
        <button
          onClick={onBack}
          style={{
            width: 36, height: 36,
            borderRadius: 10,
            border: `1px solid ${tokens.border}`,
            background: tokens.surface,
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, color: tokens.textPrimary,
          }}
        >←</button>
      ) : <div style={{ width: 36 }} />}
      <span style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 16, fontWeight: 700,
        color: tokens.textPrimary,
        letterSpacing: '-0.02em',
      }}>{title}</span>
      {rightIcon ? (
        <button
          onClick={rightAction}
          style={{
            width: 36, height: 36,
            borderRadius: 10,
            border: 'none',
            background: tokens.primarySubtle,
            cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 16, color: tokens.primary,
            fontWeight: 600,
          }}
        >{rightIcon}</button>
      ) : <div style={{ width: 36 }} />}
    </div>
  );
}

// ══ PANTALLA: LOGIN / REGISTER ══════════════════════════════════════════════
function LoginScreen({ tokens, tweaks }) {
  const [mode, setMode] = useStateX('login');
  const [email, setEmail] = useStateX('');
  const [password, setPassword] = useStateX('');
  const [name, setName] = useStateX('');
  const [confirm, setConfirm] = useStateX('');
  const [loading, setLoading] = useStateX(false);
  const { InputField, AppButton } = window;

  const handleSubmit = () => {
    setLoading(true);
    setTimeout(() => setLoading(false), 1500);
  };

  return (
    <div style={{ padding: '40px 24px 0', display: 'flex', flexDirection: 'column', height: '100%' }}>
      {/* Logo + tagline */}
      <div style={{
        marginBottom: 36,
        animation: 'fadeUp 400ms ease both',
      }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 32, fontWeight: 800,
          letterSpacing: '-0.04em',
          color: tokens.textPrimary,
          lineHeight: 1,
        }}>bruma<span style={{ color: tokens.primary }}>.</span></div>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 14,
          color: tokens.textSecondary,
          marginTop: 8,
        }}>Tu dinero, sin ansiedad.</div>
      </div>

      {/* Form */}
      <div style={{
        display: 'flex', flexDirection: 'column', gap: 14,
        animation: 'fadeUp 400ms 100ms ease both',
      }}>
        {mode === 'register' && (
          <InputField label="Nombre completo" value={name} onChange={setName} tokens={tokens} />
        )}
        <InputField label="Email" value={email} onChange={setEmail} tokens={tokens} type="email" />
        <InputField label="Contraseña" value={password} onChange={setPassword} tokens={tokens} type="password" />
        {mode === 'register' && (
          <InputField label="Confirmar contraseña" value={confirm} onChange={setConfirm} tokens={tokens} type="password" />
        )}

        {mode === 'login' && (
          <div style={{ textAlign: 'right', marginTop: -4 }}>
            <span style={{
              fontFamily: "'DM Sans', sans-serif",
              fontSize: 13, fontWeight: 500,
              color: tokens.primary, cursor: 'pointer',
            }}>¿Olvidaste tu contraseña?</span>
          </div>
        )}

        <div style={{ marginTop: 6 }}>
          <AppButton
            label={mode === 'login' ? 'Iniciar sesión' : 'Crear cuenta'}
            tokens={tokens}
            onClick={handleSubmit}
            loading={loading}
          />
        </div>

        {/* Divider o */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '8px 0' }}>
          <div style={{ flex: 1, height: 1, background: tokens.border }} />
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 12, color: tokens.textTertiary,
          }}>o</span>
          <div style={{ flex: 1, height: 1, background: tokens.border }} />
        </div>

        {/* Google */}
        <button style={{
          height: 52,
          background: tokens.surface,
          border: `1px solid ${tokens.border}`,
          borderRadius: 14,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 10, cursor: 'pointer',
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 15, fontWeight: 600,
          color: tokens.textPrimary,
        }}>
          <span style={{
            width: 16, height: 16, borderRadius: '50%',
            background: 'conic-gradient(from 0deg, #EA4335, #FBBC05, #34A853, #4285F4, #EA4335)',
            display: 'inline-block',
          }} />
          Continuar con Google
        </button>
      </div>

      <div style={{ flex: 1 }} />

      {/* Toggle login/register */}
      <div style={{
        textAlign: 'center', paddingBottom: 24,
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 13, color: tokens.textSecondary,
        animation: 'fadeUp 400ms 200ms ease both',
      }}>
        {mode === 'login' ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}
        <span
          onClick={() => setMode(mode === 'login' ? 'register' : 'login')}
          style={{ color: tokens.primary, fontWeight: 600, cursor: 'pointer' }}
        >{mode === 'login' ? 'Regístrate' : 'Inicia sesión'}</span>
      </div>
    </div>
  );
}

// ══ PANTALLA: STATS / BUDGET ════════════════════════════════════════════════
function StatsScreen({ tokens, tweaks }) {
  const { AppCard, CATEGORY_COLORS, CATEGORY_ICONS } = window;
  const [visible, setVisible] = useStateX(false);
  useEffectX(() => { setTimeout(() => setVisible(true), 100); }, []);

  return (
    <div style={{ padding: '20px 20px 0' }}>
      {/* Header */}
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 24,
        animation: 'fadeUp 400ms ease both',
      }}>
        <span style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 22, fontWeight: 700,
          color: tokens.textPrimary,
          letterSpacing: '-0.03em',
        }}>Finanzas</span>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 10,
          padding: '8px 14px',
          background: tokens.surface,
          border: `1px solid ${tokens.border}`,
          borderRadius: 100,
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 13, fontWeight: 600,
          color: tokens.textPrimary,
          cursor: 'pointer',
        }}>
          <span style={{ color: tokens.textSecondary }}>‹</span>
          Mayo 2025
          <span style={{ color: tokens.textSecondary }}>›</span>
        </div>
      </div>

      {/* Resumen del mes */}
      <AppCard tokens={tokens} padding={20} style={{ marginBottom: 28, animation: 'fadeUp 400ms 100ms ease both' }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 13, fontWeight: 600,
          color: tokens.textSecondary,
          marginBottom: 16,
        }}>Resumen del mes</div>
        <div style={{ display: 'flex', justifyContent: 'space-between' }}>
          {[
            { label: 'Ingresos', value: 24500, color: tokens.success },
            { label: 'Gastos', value: 6420, color: tokens.error },
            { label: 'Ahorro', value: 18080, color: tokens.primary },
          ].map(m => (
            <div key={m.label}>
              <div style={{
                fontFamily: "'DM Sans', sans-serif",
                fontSize: 10, fontWeight: 600,
                color: tokens.textSecondary,
                letterSpacing: '0.08em',
                textTransform: 'uppercase',
                marginBottom: 6,
              }}>{m.label}</div>
              <div style={{
                fontFamily: "'DM Sans', sans-serif",
                fontSize: 20, fontWeight: 700,
                color: m.color,
                fontVariantNumeric: 'tabular-nums',
                letterSpacing: '-0.02em',
              }}>${(m.value / 1000).toFixed(1)}k</div>
            </div>
          ))}
        </div>
      </AppCard>

      {/* Gastos por categoría */}
      <div style={{ marginBottom: 28, animation: 'fadeUp 400ms 200ms ease both' }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 17, fontWeight: 700,
          color: tokens.textPrimary,
          letterSpacing: '-0.02em',
          marginBottom: 14,
        }}>Gastos por categoría</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {CATEGORY_BREAKDOWN.map((c, i) => {
            const color = CATEGORY_COLORS[c.category];
            return (
              <div key={c.category} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 36, height: 36, borderRadius: 10,
                  background: `${color}18`,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 16, color,
                }}>{CATEGORY_ICONS[c.category]}</div>
                <div style={{ flex: 1 }}>
                  <div style={{
                    display: 'flex', justifyContent: 'space-between',
                    marginBottom: 6,
                  }}>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 14, fontWeight: 500,
                      color: tokens.textPrimary,
                    }}>{c.label}</span>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 13, fontWeight: 600,
                      color: tokens.textSecondary,
                      fontVariantNumeric: 'tabular-nums',
                    }}>{c.pct}%</span>
                  </div>
                  <div style={{
                    height: 6, borderRadius: 3,
                    background: tokens.primarySubtle,
                    overflow: 'hidden',
                  }}>
                    <div style={{
                      height: '100%',
                      width: visible ? `${c.pct}%` : '0%',
                      background: color,
                      borderRadius: 3,
                      transition: 'width 800ms cubic-bezier(0.34, 1.56, 0.64, 1)',
                      transitionDelay: `${i * 80}ms`,
                    }} />
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Presupuestos */}
      <div style={{ animation: 'fadeUp 400ms 300ms ease both' }}>
        <div style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          marginBottom: 14,
        }}>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 17, fontWeight: 700,
            color: tokens.textPrimary,
            letterSpacing: '-0.02em',
          }}>Presupuestos</span>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 13, fontWeight: 600,
            color: tokens.primary, cursor: 'pointer',
          }}>+ Nuevo</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {SAMPLE_BUDGETS.map((b, i) => {
            const pct = (b.spent / b.total) * 100;
            const status = pct < 50 ? 'success' : pct <= 80 ? 'warning' : 'error';
            const barColor = tokens[status];
            return (
              <AppCard key={b.id} tokens={tokens} padding={16}>
                <div style={{
                  display: 'flex', justifyContent: 'space-between',
                  marginBottom: 10,
                }}>
                  <div>
                    <div style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 15, fontWeight: 600,
                      color: tokens.textPrimary,
                    }}>{b.name}</div>
                    <div style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 12,
                      color: tokens.textSecondary,
                      marginTop: 2,
                      fontVariantNumeric: 'tabular-nums',
                    }}>${b.spent.toLocaleString('es-MX')} / ${b.total.toLocaleString('es-MX')}</div>
                  </div>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 16, fontWeight: 700,
                    color: barColor,
                    fontVariantNumeric: 'tabular-nums',
                    letterSpacing: '-0.02em',
                  }}>{Math.round(pct)}%</div>
                </div>
                <div style={{
                  height: 6, borderRadius: 3,
                  background: tokens.primarySubtle,
                  overflow: 'hidden',
                }}>
                  <div style={{
                    height: '100%',
                    width: visible ? `${Math.min(pct, 100)}%` : '0%',
                    background: barColor,
                    borderRadius: 3,
                    transition: 'width 800ms cubic-bezier(0.34, 1.56, 0.64, 1)',
                    transitionDelay: `${400 + i * 100}ms`,
                  }} />
                </div>
              </AppCard>
            );
          })}
        </div>
      </div>
    </div>
  );
}

// ══ MEMBER AVATARS STACK ════════════════════════════════════════════════════
function AvatarStack({ members, size = 24, tokens, max = 3 }) {
  const visible = members.slice(0, max);
  const overflow = members.length - max;
  return (
    <div style={{ display: 'flex' }}>
      {visible.map((m, i) => (
        <div key={i} style={{
          width: size, height: size,
          borderRadius: '50%',
          background: m.color,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: "'DM Sans', sans-serif",
          fontSize: size * 0.42,
          fontWeight: 600,
          color: '#FFFFFF',
          marginLeft: i === 0 ? 0 : -8,
          border: `2px solid ${tokens.surface}`,
          zIndex: visible.length - i,
        }}>{m.name.charAt(0)}</div>
      ))}
      {overflow > 0 && (
        <div style={{
          width: size, height: size,
          borderRadius: '50%',
          background: tokens.surfaceAlt,
          border: `2px solid ${tokens.surface}`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontFamily: "'DM Sans', sans-serif",
          fontSize: size * 0.38,
          fontWeight: 600,
          color: tokens.textSecondary,
          marginLeft: -8,
        }}>+{overflow}</div>
      )}
    </div>
  );
}

// ══ PANTALLA: SHARED SPACES ═════════════════════════════════════════════════
function SpacesScreen({ tokens, tweaks }) {
  const { AppCard } = window;

  const balanceColor = (b) => b > 0 ? tokens.success : b < 0 ? tokens.error : tokens.textSecondary;
  const balanceText = (b) => {
    if (b > 0) return `+$${Math.abs(b).toLocaleString('es-MX')}`;
    if (b < 0) return `-$${Math.abs(b).toLocaleString('es-MX')}`;
    return '$0';
  };

  return (
    <div style={{ padding: '20px 20px 0' }}>
      <div style={{
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        marginBottom: 24,
        animation: 'fadeUp 400ms ease both',
      }}>
        <span style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 22, fontWeight: 700,
          color: tokens.textPrimary,
          letterSpacing: '-0.03em',
        }}>Grupos</span>
        <button style={{
          width: 36, height: 36,
          borderRadius: 10,
          border: 'none',
          background: tokens.primarySubtle,
          color: tokens.primary,
          fontSize: 18, fontWeight: 600,
          cursor: 'pointer',
        }}>+</button>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {SAMPLE_SPACES.map((s, i) => (
          <div key={s.id} style={{ animation: `fadeUp 400ms ${100 + i * 80}ms ease both` }}>
            <AppCard tokens={tokens} padding={16} onTap={() => {}}>
              <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 15, fontWeight: 500,
                      color: tokens.textPrimary,
                    }}>{s.name}</span>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 10, fontWeight: 600,
                      color: tokens.success,
                      background: `${tokens.success}15`,
                      padding: '2px 8px',
                      borderRadius: 100,
                    }}>{s.status}</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <AvatarStack members={s.members} tokens={tokens} max={3} />
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 12,
                      color: tokens.textSecondary,
                    }}>{s.members.length} miembros</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 16, fontWeight: 700,
                    color: balanceColor(s.userBalance),
                    fontVariantNumeric: 'tabular-nums',
                    letterSpacing: '-0.02em',
                  }}>{balanceText(s.userBalance)}</div>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 11,
                    color: tokens.textTertiary,
                    marginTop: 2,
                  }}>
                    {s.userBalance > 0 ? 'te deben' : s.userBalance < 0 ? 'debes' : 'al día'}
                  </div>
                </div>
              </div>
            </AppCard>
          </div>
        ))}

        <div style={{
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          padding: 16, marginTop: 4,
          borderRadius: 20,
          border: `1px dashed ${tokens.border}`,
          cursor: 'pointer',
          animation: 'fadeUp 400ms 400ms ease both',
        }}>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 14, fontWeight: 600,
            color: tokens.primary,
          }}>+ Crear nuevo grupo</span>
        </div>
      </div>
    </div>
  );
}

// ══ PANTALLA: SHARED SPACE DETAIL ═══════════════════════════════════════════
function SpaceDetailScreen({ tokens, tweaks }) {
  const { AppCard, AppButton, TransactionItem } = window;
  const space = SAMPLE_SPACES[0]; // Depa Cumbres
  const memberBalances = [
    { ...space.members[0], balance: 450 },   // Tú
    { ...space.members[1], balance: -260 },  // Carlos
    { ...space.members[2], balance: -190 },  // Ana
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <ScreenHeader tokens={tokens} title={space.name} onBack={() => {}} rightIcon="⚙" />

      <div style={{ padding: '0 20px', flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        {/* Balance card */}
        <div style={{
          background: tokens.primarySubtle,
          border: `1px solid ${tokens.primary}30`,
          borderRadius: 20,
          padding: 20,
          marginBottom: 24,
          animation: 'fadeUp 400ms ease both',
        }}>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 11, fontWeight: 600,
            color: tokens.textSecondary,
            letterSpacing: '0.08em',
            textTransform: 'uppercase',
            marginBottom: 8,
          }}>Tu balance</div>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 36, fontWeight: 700,
            color: tokens.success,
            letterSpacing: '-0.03em',
            fontVariantNumeric: 'tabular-nums',
            lineHeight: 1.1,
          }}>+$450.00</div>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 13,
            color: tokens.textSecondary,
            marginTop: 6,
          }}>Carlos y Ana te deben</div>
        </div>

        {/* Miembros */}
        <div style={{ marginBottom: 24, animation: 'fadeUp 400ms 100ms ease both' }}>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 17, fontWeight: 700,
            color: tokens.textPrimary,
            letterSpacing: '-0.02em',
            marginBottom: 14,
          }}>Miembros</div>
          <div style={{ display: 'flex', gap: 16, overflowX: 'auto', paddingBottom: 4 }}>
            {memberBalances.map((m, i) => (
              <div key={i} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8,
                flexShrink: 0, width: 64,
              }}>
                <div style={{
                  width: 48, height: 48,
                  borderRadius: '50%',
                  background: m.color,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: "'DM Sans', sans-serif",
                  fontSize: 18, fontWeight: 700,
                  color: '#FFFFFF',
                }}>{m.name.charAt(0)}</div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 11, fontWeight: 500,
                    color: tokens.textPrimary,
                  }}>{i === 0 ? 'Tú' : m.name}</div>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 11, fontWeight: 600,
                    color: m.balance > 0 ? tokens.success : m.balance < 0 ? tokens.error : tokens.textSecondary,
                    fontVariantNumeric: 'tabular-nums',
                    marginTop: 2,
                  }}>{m.balance > 0 ? '+' : m.balance < 0 ? '-' : ''}${Math.abs(m.balance)}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Gastos del grupo */}
        <div style={{ animation: 'fadeUp 400ms 200ms ease both' }}>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 17, fontWeight: 700,
            color: tokens.textPrimary,
            letterSpacing: '-0.02em',
            marginBottom: 12,
          }}>Gastos del grupo</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            {SPACE_TXS.map((tx, i) => (
              <div key={tx.id}>
                <TransactionItem transaction={tx} tokens={tokens} index={i} />
                <div style={{
                  fontFamily: "'DM Sans', sans-serif",
                  fontSize: 11,
                  color: tokens.textTertiary,
                  paddingLeft: 68,
                  marginTop: -6,
                  marginBottom: 4,
                }}>• Pagó {tx.payer}</div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Botón flotante */}
      <div style={{
        position: 'absolute',
        bottom: 100, left: 20, right: 20,
        animation: 'fadeUp 400ms 300ms ease both',
      }}>
        <AppButton label="Registrar gasto del grupo" tokens={tokens} onClick={() => {}} />
      </div>
    </div>
  );
}

// ══ PANTALLA: TRANSACTION DETAIL ════════════════════════════════════════════
function TransactionDetailScreen({ tokens, tweaks }) {
  const { AppCard, CATEGORY_COLORS, CATEGORY_ICONS } = window;
  const tx = { title: 'Oxxo Garibaldi', amount: -148.50, category: 'food', date: 'Hoy, 14:22', account: 'Efectivo' };
  const color = CATEGORY_COLORS[tx.category];

  const infoRows = [
    { label: 'Categoría', value: 'Comida' },
    { label: 'Cuenta', value: tx.account },
    { label: 'Fecha', value: '4 mayo 2025, 14:22' },
    { label: 'Notas', value: '—' },
  ];

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      <ScreenHeader tokens={tokens} title="Detalle" onBack={() => {}} />

      <div style={{ padding: '0 20px', flex: 1, overflowY: 'auto', paddingBottom: 80 }}>
        {/* Hero */}
        <div style={{
          textAlign: 'center', marginBottom: 28,
          animation: 'fadeUp 400ms ease both',
        }}>
          <div style={{
            width: 72, height: 72,
            borderRadius: 20,
            background: `${color}18`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 32,
            margin: '0 auto 16px',
            color,
          }}>{CATEGORY_ICONS[tx.category]}</div>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 40, fontWeight: 700,
            color: tokens.error,
            letterSpacing: '-0.03em',
            fontVariantNumeric: 'tabular-nums',
            lineHeight: 1.05,
          }}>-$148.50</div>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 22, fontWeight: 700,
            color: tokens.textPrimary,
            letterSpacing: '-0.03em',
            marginTop: 8,
          }}>{tx.title}</div>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 14,
            color: tokens.textSecondary,
            marginTop: 4,
          }}>{tx.date} · {tx.account}</div>
        </div>

        {/* Info card */}
        <AppCard tokens={tokens} padding={0} style={{ marginBottom: 28, animation: 'fadeUp 400ms 100ms ease both', overflow: 'hidden' }}>
          {infoRows.map((r, i) => (
            <div key={r.label}>
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '0 16px', height: 44,
              }}>
                <span style={{
                  fontFamily: "'DM Sans', sans-serif",
                  fontSize: 12,
                  color: tokens.textSecondary,
                }}>{r.label}</span>
                <span style={{
                  fontFamily: "'DM Sans', sans-serif",
                  fontSize: 14, fontWeight: 500,
                  color: tokens.textPrimary,
                }}>{r.value}</span>
              </div>
              {i < infoRows.length - 1 && <Divider tokens={tokens} margin="0 16px" />}
            </div>
          ))}
        </AppCard>

        {/* Comentarios */}
        <div style={{ animation: 'fadeUp 400ms 200ms ease both' }}>
          <div style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 17, fontWeight: 700,
            color: tokens.textPrimary,
            letterSpacing: '-0.02em',
            marginBottom: 14,
          }}>Comentarios</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14, marginBottom: 16 }}>
            {SAMPLE_COMMENTS.map(c => (
              <div key={c.id} style={{ display: 'flex', gap: 10 }}>
                <div style={{
                  width: 32, height: 32,
                  borderRadius: '50%',
                  background: c.color,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontFamily: "'DM Sans', sans-serif",
                  fontSize: 12, fontWeight: 700,
                  color: '#FFFFFF',
                  flexShrink: 0,
                }}>{c.initial}</div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 2 }}>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 13, fontWeight: 600,
                      color: tokens.textPrimary,
                    }}>{c.name}</span>
                    <span style={{
                      fontFamily: "'DM Sans', sans-serif",
                      fontSize: 11,
                      color: tokens.textTertiary,
                    }}>{c.time}</span>
                  </div>
                  <div style={{
                    fontFamily: "'DM Sans', sans-serif",
                    fontSize: 14,
                    color: tokens.textPrimary,
                    lineHeight: 1.4,
                  }}>{c.text}</div>
                </div>
              </div>
            ))}
          </div>

          {/* Input */}
          <div style={{
            display: 'flex', alignItems: 'center', gap: 8,
            background: tokens.surfaceAlt,
            border: `1px solid ${tokens.border}`,
            borderRadius: 14,
            padding: '6px 6px 6px 14px',
            height: 48,
          }}>
            <input
              placeholder="Agregar comentario..."
              style={{
                flex: 1,
                border: 'none', background: 'transparent',
                fontFamily: "'DM Sans', sans-serif",
                fontSize: 14,
                color: tokens.textPrimary,
                outline: 'none',
              }}
            />
            <button style={{
              width: 36, height: 36,
              borderRadius: '50%',
              background: tokens.primary,
              border: 'none',
              color: tokens.onPrimary,
              fontSize: 16, fontWeight: 700,
              cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>↑</button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ══ PANTALLA: TRANSFER (bottom sheet sobre Home) ════════════════════════════
function TransferSheet({ tokens, tweaks }) {
  const { AppCard, AppButton, InputField } = window;
  const [origin] = useStateX({ name: 'BBVA Débito', balance: 28450.50, type: 'banco' });
  const [dest] = useStateX({ name: 'GBM Inversiones', balance: 45000, type: 'inversion' });
  const [amount, setAmount] = useStateX('5000');
  const [notes, setNotes] = useStateX('');

  const AccountPicker = ({ acc }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: 14,
      background: tokens.surface,
      border: `1px solid ${tokens.border}`,
      borderRadius: 14,
      cursor: 'pointer',
    }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10,
        background: tokens.primarySubtle,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: 16, color: tokens.primary,
      }}>{acc.type === 'banco' ? '🏦' : acc.type === 'inversion' ? '📈' : '💵'}</div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 14, fontWeight: 600,
          color: tokens.textPrimary,
        }}>{acc.name}</div>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 12,
          color: tokens.textSecondary,
          fontVariantNumeric: 'tabular-nums',
        }}>${acc.balance.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</div>
      </div>
      <span style={{ color: tokens.textTertiary, fontSize: 16 }}>›</span>
    </div>
  );

  return (
    <>
      {/* Overlay */}
      <div style={{
        position: 'absolute', inset: 0,
        background: 'rgba(0,0,0,0.55)',
        zIndex: 200,
        animation: 'fadeUp 300ms ease both',
      }} />

      {/* Sheet */}
      <div style={{
        position: 'absolute',
        bottom: 0, left: 0, right: 0,
        background: tokens.bg,
        borderRadius: '24px 24px 0 0',
        padding: '12px 20px 28px',
        zIndex: 201,
        maxHeight: '88%',
        overflowY: 'auto',
        animation: 'sheetUp 400ms cubic-bezier(0.34, 1.4, 0.64, 1) both',
        boxShadow: '0 -20px 60px rgba(0,0,0,0.3)',
      }}>
        {/* Drag handle */}
        <div style={{
          width: 40, height: 4,
          borderRadius: 2,
          background: tokens.border,
          margin: '0 auto 16px',
        }} />

        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 17, fontWeight: 700,
          color: tokens.textPrimary,
          letterSpacing: '-0.02em',
          marginBottom: 20,
        }}>Transferencia</div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Origen */}
          <div>
            <div style={{
              fontFamily: "'DM Sans', sans-serif",
              fontSize: 12, fontWeight: 500,
              color: tokens.textSecondary,
              marginBottom: 6,
            }}>Origen</div>
            <AccountPicker acc={origin} />
          </div>

          {/* Switch icon */}
          <div style={{ display: 'flex', justifyContent: 'center', margin: -8 }}>
            <div style={{
              width: 36, height: 36,
              borderRadius: 12,
              background: tokens.surfaceAlt,
              border: `1px solid ${tokens.border}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 14, color: tokens.textSecondary,
              cursor: 'pointer',
            }}>↕</div>
          </div>

          {/* Destino */}
          <div>
            <div style={{
              fontFamily: "'DM Sans', sans-serif",
              fontSize: 12, fontWeight: 500,
              color: tokens.textSecondary,
              marginBottom: 6,
            }}>Destino</div>
            <AccountPicker acc={dest} />
          </div>

          <InputField label="Monto" value={amount} onChange={setAmount} tokens={tokens} type="number" prefix="$" />
          <InputField label="Notas (opcional)" value={notes} onChange={setNotes} tokens={tokens} />

          <div style={{ marginTop: 4 }}>
            <AppButton label="Realizar transferencia" tokens={tokens} onClick={() => {}} />
          </div>
        </div>
      </div>
    </>
  );
}

// Mini home pasivo para ver detrás del overlay
function HomePassive({ tokens, tweaks }) {
  return <window.HomeScreen tokens={tokens} tweaks={tweaks} />;
}

function TransferScreen({ tokens, tweaks }) {
  return (
    <div style={{ height: '100%', position: 'relative' }}>
      <div style={{ height: '100%', overflow: 'hidden' }}>
        <window.HomeScreen tokens={tokens} tweaks={tweaks} />
      </div>
      <TransferSheet tokens={tokens} tweaks={tweaks} />
    </div>
  );
}

Object.assign(window, {
  LoginScreen,
  StatsScreen,
  SpacesScreen,
  SpaceDetailScreen,
  TransactionDetailScreen,
  TransferScreen,
});
