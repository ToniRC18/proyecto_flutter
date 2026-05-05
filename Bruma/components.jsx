
// ─── BRUMA — Componentes compartidos ───────────────────────────────────────
// Todos los widgets reutilizables del sistema de diseño Bruma

// ── Tokens de diseño ──────────────────────────────────────────────────────
const THEMES = {
  mint: {
    primary: '#00D4AA',
    primaryDark: '#00EFBF',
    onPrimary: '#001A14',
    accent: '#FF6B35',
  },
  ember: {
    primary: '#FF6B35',
    primaryDark: '#FF8C5A',
    onPrimary: '#FFFFFF',
    accent: '#00D4AA',
  },
  cobalt: {
    primary: '#0066FF',
    primaryDark: '#3385FF',
    onPrimary: '#FFFFFF',
    accent: '#FF6B35',
  },
};

const makeTokens = (tweak) => {
  const t = THEMES[tweak.colorTheme] || THEMES.mint;
  const dark = tweak.darkMode;
  return {
    // Colores base
    bg:             dark ? '#090C0E' : '#F2F5F8',
    bgSecondary:    dark ? '#111518' : '#FFFFFF',
    surface:        dark ? '#161B1F' : '#FFFFFF',
    surfaceAlt:     dark ? '#1C2226' : '#F7F9FB',
    border:         dark ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.08)',
    textPrimary:    dark ? '#F0F4F8' : '#0D1117',
    textSecondary:  dark ? '#8A9099' : '#6B7280',
    textTertiary:   dark ? '#4A5260' : '#9CA3AF',
    // Colores del tema
    primary:        dark ? t.primaryDark : t.primary,
    onPrimary:      t.onPrimary,
    accent:         t.accent,
    // Estados
    success:        dark ? '#00C48C' : '#00A878',
    error:          dark ? '#FF4D6A' : '#E8284B',
    warning:        dark ? '#FFB020' : '#F59E0B',
    // Primario con opacidad
    primarySubtle:  dark ? `${t.primaryDark}18` : `${t.primary}12`,
    primaryMid:     dark ? `${t.primaryDark}30` : `${t.primary}25`,
  };
};

// ── Utilidades ────────────────────────────────────────────────────────────
const fmt = (n, currency) => {
  const sym = currency === 'USD' ? '$' : currency === 'EUR' ? '€' : '$';
  const locale = currency === 'EUR' ? 'es-MX' : 'es-MX';
  return sym + n.toLocaleString(locale, { minimumFractionDigits: 2, maximumFractionDigits: 2 });
};

// ── AnimatedNumber ─────────────────────────────────────────────────────────
function AnimatedNumber({ value, duration = 800, tokens, fontSize = 40, prefix = true, currency = 'MXN' }) {
  const [displayed, setDisplayed] = React.useState(0);
  const startRef = React.useRef(0);
  const startTimeRef = React.useRef(null);
  const rafRef = React.useRef(null);

  React.useEffect(() => {
    startRef.current = displayed;
    startTimeRef.current = null;
    const animate = (ts) => {
      if (!startTimeRef.current) startTimeRef.current = ts;
      const elapsed = ts - startTimeRef.current;
      const progress = Math.min(elapsed / duration, 1);
      // easeOutCubic
      const ease = 1 - Math.pow(1 - progress, 3);
      setDisplayed(startRef.current + (value - startRef.current) * ease);
      if (progress < 1) rafRef.current = requestAnimationFrame(animate);
    };
    rafRef.current = requestAnimationFrame(animate);
    return () => cancelAnimationFrame(rafRef.current);
  }, [value]);

  const parts = fmt(displayed, currency).split('.');
  const sym = currency === 'EUR' ? '€' : '$';

  return (
    <div style={{ display: 'flex', alignItems: 'flex-start', gap: 2 }}>
      <span style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 18,
        fontWeight: 400,
        color: tokens.textSecondary,
        paddingTop: fontSize * 0.1,
        lineHeight: 1,
        fontVariantNumeric: 'tabular-nums',
      }}>{sym}</span>
      <span style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize,
        fontWeight: 700,
        color: tokens.textPrimary,
        lineHeight: 1,
        letterSpacing: '-0.03em',
        fontVariantNumeric: 'tabular-nums',
      }}>
        {Math.round(displayed).toLocaleString('es-MX')}
        <span style={{ fontSize: fontSize * 0.5, fontWeight: 500, opacity: 0.6 }}>
          .{parts[1] || '00'}
        </span>
      </span>
    </div>
  );
}

// ── AppCard ────────────────────────────────────────────────────────────────
function AppCard({ children, tokens, padding = 16, onTap, style = {}, noBorder = false }) {
  const [pressed, setPressed] = React.useState(false);
  const [hovered, setHovered] = React.useState(false);

  return (
    <div
      onClick={onTap}
      onMouseDown={() => onTap && setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => { setHovered(false); setPressed(false); }}
      style={{
        background: tokens.surface,
        border: noBorder ? 'none' : `1px solid ${tokens.border}`,
        borderRadius: 20,
        padding,
        cursor: onTap ? 'pointer' : 'default',
        transform: pressed ? 'scale(0.985)' : 'scale(1)',
        transition: 'transform 150ms ease, box-shadow 200ms ease, background 200ms ease',
        boxShadow: hovered && onTap
          ? `0 4px 20px ${tokens.primary}14`
          : 'none',
        background: hovered && onTap
          ? tokens.surfaceAlt
          : tokens.surface,
        ...style,
      }}
    >
      {children}
    </div>
  );
}

// ── AppButton ──────────────────────────────────────────────────────────────
function AppButton({ label, tokens, onClick, loading = false, disabled = false, expanded = true, variant = 'primary', small = false }) {
  const [pressed, setPressed] = React.useState(false);

  const bg = variant === 'primary' ? tokens.primary
    : variant === 'ghost' ? 'transparent'
    : tokens.primarySubtle;

  const color = variant === 'primary' ? tokens.onPrimary
    : variant === 'ghost' ? tokens.textSecondary
    : tokens.primary;

  return (
    <button
      onClick={!disabled && !loading ? onClick : undefined}
      onMouseDown={() => setPressed(true)}
      onMouseUp={() => setPressed(false)}
      onMouseLeave={() => setPressed(false)}
      style={{
        height: small ? 40 : 52,
        width: expanded ? '100%' : 'auto',
        padding: expanded ? '0 20px' : '0 24px',
        background: bg,
        border: variant === 'ghost' ? `1px solid ${tokens.border}` : 'none',
        borderRadius: 14,
        color,
        fontFamily: "'DM Sans', sans-serif",
        fontSize: small ? 13 : 15,
        fontWeight: 600,
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.4 : 1,
        transform: pressed ? 'scale(0.97)' : 'scale(1)',
        transition: 'transform 120ms ease, opacity 200ms ease',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        letterSpacing: '-0.01em',
      }}
    >
      {loading ? (
        <div style={{
          width: 18, height: 18,
          border: `2px solid ${color}40`,
          borderTopColor: color,
          borderRadius: '50%',
          animation: 'spin 0.7s linear infinite',
        }} />
      ) : label}
    </button>
  );
}

// ── TransactionItem ────────────────────────────────────────────────────────
const CATEGORY_COLORS = {
  food:     '#FF6B35',
  transport:'#0066FF',
  shopping: '#9333EA',
  health:   '#00A878',
  home:     '#F59E0B',
  income:   '#00D4AA',
  transfer: '#6B7280',
  other:    '#EC4899',
};

const CATEGORY_ICONS = {
  food:     '🍔',
  transport:'🚌',
  shopping: '🛍',
  health:   '💊',
  home:     '🏠',
  income:   '💰',
  transfer: '↕',
  other:    '•••',
};

function TransactionItem({ transaction, tokens, index = 0 }) {
  const [visible, setVisible] = React.useState(false);
  const [hovered, setHovered] = React.useState(false);

  React.useEffect(() => {
    const t = setTimeout(() => setVisible(true), index * 40);
    return () => clearTimeout(t);
  }, []);

  const catColor = CATEGORY_COLORS[transaction.category] || CATEGORY_COLORS.other;
  const isIncome = transaction.amount > 0;

  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        padding: '10px 12px',
        borderRadius: 12,
        background: hovered ? tokens.surfaceAlt : 'transparent',
        cursor: 'pointer',
        opacity: visible ? 1 : 0,
        transform: visible ? 'translateY(0)' : 'translateY(10px)',
        transition: 'opacity 300ms ease, transform 300ms ease, background 150ms ease',
      }}
    >
      {/* Ícono de categoría */}
      <div style={{
        width: 44,
        height: 44,
        borderRadius: 12,
        background: `${catColor}18`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 18,
        flexShrink: 0,
        color: catColor,
        fontFamily: 'system-ui',
      }}>
        {CATEGORY_ICONS[transaction.category] || '•'}
      </div>

      {/* Info */}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 15,
          fontWeight: 500,
          color: tokens.textPrimary,
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}>{transaction.title}</div>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 12,
          color: tokens.textSecondary,
          marginTop: 2,
        }}>{transaction.date}</div>
      </div>

      {/* Monto */}
      <div style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 15,
        fontWeight: 600,
        color: isIncome ? tokens.success : tokens.error,
        fontVariantNumeric: 'tabular-nums',
        flexShrink: 0,
      }}>
        {isIncome ? '+' : '-'}${Math.abs(transaction.amount).toLocaleString('es-MX', { minimumFractionDigits: 2 })}
      </div>
    </div>
  );
}

// ── WeeklyChart ─────────────────────────────────────────────────────────────
function WeeklyChart({ data, tokens }) {
  const max = Math.max(...data.map(d => d.value));
  const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  const today = new Date().getDay(); // 0=Dom, 1=Lun...
  // Convertir: hoy es índice 6 en nuestro array (último)
  const todayIdx = 6;

  return (
    <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 80, padding: '0 4px' }}>
      {data.map((d, i) => {
        const pct = max > 0 ? d.value / max : 0;
        const isToday = i === todayIdx;
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
            <div style={{
              width: '100%',
              height: 64,
              display: 'flex',
              alignItems: 'flex-end',
            }}>
              <div style={{
                width: '100%',
                height: `${Math.max(pct * 100, 8)}%`,
                background: isToday ? tokens.primary : tokens.primarySubtle,
                borderRadius: 6,
                transition: 'height 600ms cubic-bezier(0.34, 1.56, 0.64, 1)',
                position: 'relative',
              }}>
                {isToday && (
                  <div style={{
                    position: 'absolute',
                    top: -20,
                    left: '50%',
                    transform: 'translateX(-50%)',
                    fontSize: 10,
                    fontFamily: "'DM Sans', sans-serif",
                    fontWeight: 600,
                    color: tokens.primary,
                    whiteSpace: 'nowrap',
                  }}>
                    ${(d.value / 1000).toFixed(1)}k
                  </div>
                )}
              </div>
            </div>
            <div style={{
              fontFamily: "'DM Sans', sans-serif",
              fontSize: 11,
              fontWeight: isToday ? 600 : 400,
              color: isToday ? tokens.primary : tokens.textTertiary,
            }}>{days[i]}</div>
          </div>
        );
      })}
    </div>
  );
}

// ── AccountCard ─────────────────────────────────────────────────────────────
function AccountCard({ account, tokens, compact = false }) {
  const [hovered, setHovered] = React.useState(false);
  const typeColors = {
    efectivo: '#00A878',
    banco: '#0066FF',
    crédito: '#FF6B35',
    inversion: '#9333EA',
  };
  const typeColor = typeColors[account.type] || tokens.primary;

  if (compact) {
    // Versión horizontal para scroll
    return (
      <div
        onMouseEnter={() => setHovered(true)}
        onMouseLeave={() => setHovered(false)}
        style={{
          width: 160,
          height: 100,
          background: hovered ? tokens.surfaceAlt : tokens.surface,
          border: `1px solid ${tokens.border}`,
          borderRadius: 20,
          padding: 16,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          cursor: 'pointer',
          flexShrink: 0,
          transition: 'background 150ms ease, transform 150ms ease',
          transform: hovered ? 'translateY(-2px)' : 'translateY(0)',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 12,
            fontWeight: 500,
            color: tokens.textSecondary,
          }}>{account.name}</span>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 10,
            fontWeight: 600,
            color: typeColor,
            background: `${typeColor}18`,
            padding: '2px 8px',
            borderRadius: 100,
          }}>{account.type}</span>
        </div>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 18,
          fontWeight: 700,
          color: tokens.textPrimary,
          fontVariantNumeric: 'tabular-nums',
          letterSpacing: '-0.02em',
        }}>
          ${account.balance.toLocaleString('es-MX', { minimumFractionDigits: 0 })}
        </div>
      </div>
    );
  }

  // Versión full para pantalla Accounts
  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        background: hovered ? tokens.surfaceAlt : tokens.surface,
        border: `1px solid ${tokens.border}`,
        borderRadius: 20,
        padding: 20,
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        cursor: 'pointer',
        transition: 'background 150ms ease, transform 150ms ease',
        transform: hovered ? 'translateY(-1px)' : 'translateY(0)',
      }}
    >
      <div style={{
        width: 44,
        height: 44,
        borderRadius: 12,
        background: `${typeColor}18`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 20,
        flexShrink: 0,
      }}>
        {account.type === 'efectivo' ? '💵' : account.type === 'banco' ? '🏦' : account.type === 'crédito' ? '💳' : '📈'}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 15,
          fontWeight: 500,
          color: tokens.textPrimary,
        }}>{account.name}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 11,
            fontWeight: 600,
            color: typeColor,
            background: `${typeColor}18`,
            padding: '2px 8px',
            borderRadius: 100,
          }}>{account.type}</span>
        </div>
      </div>
      <div style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 18,
        fontWeight: 700,
        color: tokens.textPrimary,
        fontVariantNumeric: 'tabular-nums',
        letterSpacing: '-0.02em',
      }}>
        ${account.balance.toLocaleString('es-MX', { minimumFractionDigits: 2 })}
      </div>
    </div>
  );
}

// ── InputField ──────────────────────────────────────────────────────────────
function InputField({ label, value, onChange, tokens, type = 'text', prefix, error, autoFocus = false }) {
  const [focused, setFocused] = React.useState(false);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <label style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 12,
        fontWeight: 500,
        color: focused ? tokens.primary : tokens.textSecondary,
        transition: 'color 150ms ease',
      }}>{label}</label>
      <div style={{
        display: 'flex',
        alignItems: 'center',
        background: focused ? tokens.primarySubtle : tokens.surfaceAlt,
        border: focused ? `1.5px solid ${tokens.primary}` : `1px solid ${tokens.border}`,
        borderRadius: 12,
        padding: '0 14px',
        height: 52,
        gap: 8,
        transition: 'border-color 150ms ease, background 150ms ease',
      }}>
        {prefix && (
          <span style={{
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 16,
            fontWeight: 500,
            color: tokens.textSecondary,
          }}>{prefix}</span>
        )}
        <input
          type={type}
          value={value}
          autoFocus={autoFocus}
          onChange={e => onChange(e.target.value)}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={{
            flex: 1,
            border: 'none',
            background: 'transparent',
            fontFamily: "'DM Sans', sans-serif",
            fontSize: 15,
            fontWeight: 400,
            color: tokens.textPrimary,
            outline: 'none',
            fontVariantNumeric: type === 'number' ? 'tabular-nums' : 'normal',
          }}
        />
      </div>
      {error && (
        <span style={{
          fontFamily: "'DM Sans', sans-serif",
          fontSize: 12,
          color: tokens.error,
          paddingLeft: 4,
        }}>{error}</span>
      )}
    </div>
  );
}

// ── CategoryPill ─────────────────────────────────────────────────────────────
function CategoryPill({ category, selected, tokens, onClick }) {
  const color = CATEGORY_COLORS[category] || tokens.primary;
  return (
    <button
      onClick={onClick}
      style={{
        fontFamily: "'DM Sans', sans-serif",
        fontSize: 13,
        fontWeight: selected ? 600 : 400,
        color: selected ? color : tokens.textSecondary,
        background: selected ? `${color}18` : tokens.surfaceAlt,
        border: selected ? `1px solid ${color}40` : `1px solid ${tokens.border}`,
        borderRadius: 100,
        padding: '6px 14px',
        cursor: 'pointer',
        transition: 'all 150ms ease',
        whiteSpace: 'nowrap',
      }}
    >
      {CATEGORY_ICONS[category]} {category}
    </button>
  );
}

// Exportar al scope global para uso en el archivo principal
Object.assign(window, {
  makeTokens,
  fmt,
  THEMES,
  CATEGORY_COLORS,
  CATEGORY_ICONS,
  AnimatedNumber,
  AppCard,
  AppButton,
  TransactionItem,
  WeeklyChart,
  AccountCard,
  InputField,
  CategoryPill,
});
