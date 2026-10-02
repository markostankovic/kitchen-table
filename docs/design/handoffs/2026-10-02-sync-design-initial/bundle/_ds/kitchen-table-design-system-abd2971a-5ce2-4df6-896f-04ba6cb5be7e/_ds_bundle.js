/* @ds-bundle: {"format":4,"namespace":"KitchenTableDesignSystem_abd297","components":[{"name":"Button","sourcePath":"components/actions/Button.jsx"},{"name":"IconButton","sourcePath":"components/actions/IconButton.jsx"},{"name":"SegmentedButton","sourcePath":"components/actions/SegmentedButton.jsx"},{"name":"Chip","sourcePath":"components/chips/Chip.jsx"},{"name":"FilterRow","sourcePath":"components/chips/FilterRow.jsx"},{"name":"Tag","sourcePath":"components/chips/Tag.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"Monogram","sourcePath":"components/core/Monogram.jsx"},{"name":"Banner","sourcePath":"components/feedback/Banner.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"EmptyState","sourcePath":"components/feedback/EmptyState.jsx"},{"name":"Menu","sourcePath":"components/feedback/Menu.jsx"},{"name":"Snackbar","sourcePath":"components/feedback/Snackbar.jsx"},{"name":"SearchField","sourcePath":"components/inputs/SearchField.jsx"},{"name":"TextField","sourcePath":"components/inputs/TextField.jsx"},{"name":"AppBar","sourcePath":"components/navigation/AppBar.jsx"},{"name":"KT_TABS","sourcePath":"components/navigation/NavigationBar.jsx"},{"name":"NavigationBar","sourcePath":"components/navigation/NavigationBar.jsx"},{"name":"DayCard","sourcePath":"components/plan/DayCard.jsx"},{"name":"MealEntry","sourcePath":"components/plan/MealEntry.jsx"},{"name":"IngredientRow","sourcePath":"components/recipe/IngredientRow.jsx"},{"name":"RecipeCard","sourcePath":"components/recipe/RecipeCard.jsx"},{"name":"StatRow","sourcePath":"components/recipe/StatRow.jsx"},{"name":"StepList","sourcePath":"components/recipe/StepList.jsx"},{"name":"ListRow","sourcePath":"components/settings/ListRow.jsx"},{"name":"NavRow","sourcePath":"components/settings/NavRow.jsx"},{"name":"ProfileCard","sourcePath":"components/settings/ProfileCard.jsx"},{"name":"SettingsGroup","sourcePath":"components/settings/SettingsGroup.jsx"}],"sourceHashes":{"components/actions/Button.jsx":"7e4ceb4fb250","components/actions/IconButton.jsx":"0c9057774f92","components/actions/SegmentedButton.jsx":"06173d3d3329","components/chips/Chip.jsx":"517a1153f017","components/chips/FilterRow.jsx":"7b7630eea7f1","components/chips/Tag.jsx":"f5316f988627","components/core/Card.jsx":"166461667e78","components/core/Icon.jsx":"e40645fea097","components/core/Monogram.jsx":"7b48e860706a","components/feedback/Banner.jsx":"dac2721e0866","components/feedback/Dialog.jsx":"ff37290f224d","components/feedback/EmptyState.jsx":"fe61bd2afc4a","components/feedback/Menu.jsx":"69476e784004","components/feedback/Snackbar.jsx":"fffb84df8a26","components/inputs/SearchField.jsx":"fa4d9f9b91b6","components/inputs/TextField.jsx":"bace6e5956a4","components/navigation/AppBar.jsx":"98c4c60fa890","components/navigation/NavigationBar.jsx":"ea520cc836ab","components/plan/DayCard.jsx":"117df91edc09","components/plan/MealEntry.jsx":"077b49ab974e","components/recipe/IngredientRow.jsx":"b368c3030957","components/recipe/RecipeCard.jsx":"fc39c0db0197","components/recipe/StatRow.jsx":"80fdfd41a596","components/recipe/StepList.jsx":"14da809eb64d","components/settings/ListRow.jsx":"3070ff2eea0d","components/settings/NavRow.jsx":"94da028978c5","components/settings/ProfileCard.jsx":"d22b1dbc0c50","components/settings/SettingsGroup.jsx":"3e90423d726a","ui_kits/app/App.jsx":"6c339b75ccee","ui_kits/app/HouseholdScreen.jsx":"0b86b09244ae","ui_kits/app/ListScreen.jsx":"32f84f57ea28","ui_kits/app/PlanScreen.jsx":"a9f058ab9130","ui_kits/app/RecipeDetailScreen.jsx":"1088a36708cf","ui_kits/app/RecipesScreen.jsx":"3eeae980f41c","ui_kits/app/ReviewImportScreen.jsx":"001067fc8782","ui_kits/app/SettingsScreen.jsx":"e6b6d65df9df","ui_kits/app/Shell.jsx":"39c6a7df2e41","ui_kits/app/SignInScreen.jsx":"9780fb15c5b1","ui_kits/app/data.js":"9fad28aeb661"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.KitchenTableDesignSystem_abd297 = window.KitchenTableDesignSystem_abd297 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Borderless tonal card: --card fill, radius 12, elevation 0. */
function Card({
  children,
  padding = 16,
  onClick,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onClick,
    className: onClick ? 'kt-state' : undefined,
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding,
      color: 'var(--on-surface)',
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/** Material Symbols Rounded glyph. Outlined by default; filled for selected nav, favourite, rating. */
function Icon({
  name,
  size = 24,
  filled = false,
  color,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("span", _extends({
    "aria-hidden": "true",
    className: 'kt-icon' + (filled ? ' filled' : ''),
    style: {
      fontSize: size,
      width: size,
      height: size,
      color,
      fontVariationSettings: `"FILL" ${filled ? 1 : 0}, "wght" 400, "GRAD" 0, "opsz" ${Math.min(48, Math.max(20, size))}`,
      ...style
    }
  }, rest), name);
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/actions/Button.jsx
try { (() => {
const V = {
  filled: {
    background: 'var(--primary)',
    color: 'var(--on-primary)'
  },
  tonal: {
    background: 'var(--secondary-container)',
    color: 'var(--on-secondary-container)'
  },
  outlined: {
    background: 'transparent',
    color: 'var(--primary)',
    boxShadow: 'inset 0 0 0 1px var(--outline)'
  },
  neutral: {
    background: 'transparent',
    color: 'var(--on-surface)',
    boxShadow: 'inset 0 0 0 1px var(--outline)'
  },
  text: {
    background: 'transparent',
    color: 'var(--primary)',
    padding: '0 12px'
  },
  destructive: {
    background: 'transparent',
    color: 'var(--destructive)',
    padding: '0 12px'
  },
  google: {
    background: 'var(--surface-container-lowest)',
    color: 'var(--on-surface)',
    boxShadow: 'inset 0 0 0 1px var(--outline)',
    height: 'var(--size-button-signin)'
  }
};
/** Stadium button, 48dp, labelLarge. One filled button per screen. */
function Button({
  variant = 'filled',
  icon,
  children,
  disabled,
  fullWidth,
  onClick,
  type = 'button',
  style
}) {
  const v = V[variant] || V.filled;
  const dis = disabled ? {
    background: variant === 'filled' || variant === 'tonal' ? 'color-mix(in srgb, var(--on-surface) 12%, transparent)' : 'transparent',
    color: 'color-mix(in srgb, var(--on-surface) 38%, transparent)',
    boxShadow: v.boxShadow ? 'inset 0 0 0 1px color-mix(in srgb, var(--on-surface) 12%, transparent)' : 'none'
  } : {};
  return /*#__PURE__*/React.createElement("button", {
    type: type,
    disabled: disabled,
    onClick: onClick,
    className: "kt-state",
    style: {
      height: 'var(--size-button)',
      minWidth: 48,
      padding: icon ? '0 24px 0 16px' : '0 24px',
      border: 0,
      borderRadius: 'var(--radius-full)',
      font: 'var(--type-label-large)',
      display: fullWidth ? 'flex' : 'inline-flex',
      width: fullWidth ? '100%' : undefined,
      alignItems: 'center',
      justifyContent: 'center',
      gap: 8,
      whiteSpace: 'nowrap',
      flex: 'none',
      ...v,
      ...dis,
      ...style
    }
  }, icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20
  }), children);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/Button.jsx", error: String((e && e.message) || e) }); }

// components/actions/IconButton.jsx
try { (() => {
const V = {
  standard: {
    background: 'transparent',
    color: 'var(--on-surface)'
  },
  tonal: {
    background: 'var(--surface-container-highest)',
    color: 'var(--on-surface-variant)'
  },
  container: {
    background: 'var(--primary-container)',
    color: 'var(--on-primary-container)'
  },
  onImage: {
    background: 'var(--surface)',
    color: 'var(--on-surface)'
  }
};
/** 48dp round icon button. */
function IconButton({
  icon,
  variant = 'standard',
  filled,
  color,
  label,
  size = 48,
  onClick,
  style
}) {
  const v = V[variant] || V.standard;
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": label || icon,
    onClick: onClick,
    className: "kt-state",
    style: {
      width: size,
      height: size,
      flex: 'none',
      border: 0,
      padding: 0,
      borderRadius: variant === 'container' ? 'var(--radius-lg)' : '50%',
      display: 'grid',
      placeItems: 'center',
      ...v,
      color: color || v.color,
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    filled: filled,
    size: 24
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/actions/SegmentedButton.jsx
try { (() => {
/** Outlined stadium segmented control. Selected segment: mustard fill + check (or its own icon). */
function SegmentedButton({
  options,
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "radiogroup",
    style: {
      display: 'flex',
      height: 48,
      borderRadius: 'var(--radius-full)',
      boxShadow: 'inset 0 0 0 1px var(--outline)',
      overflow: 'hidden',
      ...style
    }
  }, options.map((o, i) => {
    const opt = typeof o === 'string' ? {
      value: o,
      label: o
    } : o;
    const sel = opt.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: opt.value,
      role: "radio",
      "aria-checked": sel,
      type: "button",
      onClick: () => onChange && onChange(opt.value),
      className: "kt-state",
      style: {
        flex: 1,
        minWidth: 0,
        border: 0,
        borderLeft: i ? '1px solid var(--outline)' : 0,
        background: sel ? 'var(--secondary-container)' : 'transparent',
        color: sel ? 'var(--on-secondary-container)' : 'var(--on-surface)',
        font: 'var(--type-label-large)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        padding: '0 12px',
        whiteSpace: 'nowrap'
      }
    }, opt.icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: opt.icon,
      size: 18
    }) : sel ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: "check",
      size: 18
    }) : null, opt.label);
  }));
}
Object.assign(__ds_scope, { SegmentedButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/actions/SegmentedButton.jsx", error: String((e && e.message) || e) }); }

// components/chips/Chip.jsx
try { (() => {
/** Filter chip 40dp / input tag 32dp, radius 8. */
function Chip({
  label,
  selected,
  variant = 'filter',
  onClick,
  onRemove,
  style
}) {
  const base = {
    flex: 'none',
    display: 'inline-flex',
    alignItems: 'center',
    gap: 8,
    borderRadius: 'var(--radius-sm)',
    border: 0,
    font: 'var(--type-label-large)',
    whiteSpace: 'nowrap'
  };
  if (variant === 'input') return /*#__PURE__*/React.createElement("span", {
    style: {
      ...base,
      height: 'var(--size-tag)',
      padding: '0 8px 0 12px',
      boxShadow: 'inset 0 0 0 1px var(--outline-variant)',
      color: 'var(--on-surface)',
      ...style
    }
  }, label, /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": 'Remove ' + label,
    onClick: onRemove,
    className: "kt-state",
    style: {
      border: 0,
      background: 'none',
      padding: 0,
      color: 'var(--on-surface-variant)',
      borderRadius: '50%',
      display: 'grid'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "close",
    size: 18
  })));
  if (variant === 'clear') return /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onClick,
    className: "kt-state",
    style: {
      ...base,
      height: 'var(--size-chip)',
      padding: '0 16px 0 8px',
      background: 'transparent',
      boxShadow: 'inset 0 0 0 1px var(--outline)',
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "close",
    size: 18
  }), label || 'Clear');
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-pressed": !!selected,
    onClick: onClick,
    className: "kt-state",
    style: {
      ...base,
      height: 'var(--size-chip)',
      padding: selected ? '0 16px 0 8px' : '0 16px',
      background: selected ? 'var(--secondary-container)' : 'var(--surface-container-highest)',
      color: selected ? 'var(--on-secondary-container)' : 'var(--on-surface)',
      ...style
    }
  }, selected && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    size: 18
  }), label);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/chips/Chip.jsx", error: String((e && e.message) || e) }); }

// components/chips/FilterRow.jsx
try { (() => {
/** Horizontally scrolling filter chips; "Clear" leads (plus a 1dp divider) only while a filter is on. Never wraps. */
function FilterRow({
  filters,
  selected = [],
  onToggle,
  onClear,
  style
}) {
  const any = selected.length > 0;
  return /*#__PURE__*/React.createElement("div", {
    className: "kt-noscroll",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      overflowX: 'auto',
      paddingLeft: 'var(--gutter)',
      marginRight: 0,
      ...style
    }
  }, any && /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(__ds_scope.Chip, {
    variant: "clear",
    label: "Clear",
    onClick: onClear
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 1,
      height: 24,
      background: 'var(--outline-variant)',
      flex: 'none'
    }
  })), filters.map(f => /*#__PURE__*/React.createElement(__ds_scope.Chip, {
    key: f,
    label: f,
    selected: selected.includes(f),
    onClick: () => onToggle && onToggle(f)
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      width: 8,
      flex: 'none'
    }
  }));
}
Object.assign(__ds_scope, { FilterRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/chips/FilterRow.jsx", error: String((e && e.message) || e) }); }

// components/chips/Tag.jsx
try { (() => {
/** Small status tags: Draft, Machine translation, document language, Today. */
function Tag({
  variant = 'draft',
  children,
  code,
  style
}) {
  const base = {
    display: 'inline-flex',
    alignItems: 'center',
    gap: 4,
    flex: 'none',
    font: 'var(--type-label-medium)',
    whiteSpace: 'nowrap'
  };
  if (variant === 'today') return /*#__PURE__*/React.createElement("span", {
    style: {
      ...base,
      height: 24,
      padding: '0 10px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--today)',
      color: 'var(--on-primary)',
      fontWeight: 600,
      ...style
    }
  }, children || 'Today');
  if (variant === 'machineTranslation') return /*#__PURE__*/React.createElement("span", {
    style: {
      ...base,
      height: 24,
      padding: '0 8px 0 6px',
      borderRadius: 'var(--radius-xs)',
      background: 'var(--surface-container-highest)',
      color: 'var(--on-surface-variant)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "language",
    size: 16
  }), children || 'Machine translation');
  if (variant === 'docLanguage') return /*#__PURE__*/React.createElement("span", {
    style: {
      ...base,
      height: 28,
      gap: 6,
      padding: '0 12px 0 10px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--doc-language)',
      boxShadow: 'inset 0 0 0 1px var(--doc-language-ring)',
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("b", {
    style: {
      fontWeight: 700
    }
  }, code), children);
  return /*#__PURE__*/React.createElement("span", {
    style: {
      ...base,
      height: 20,
      padding: '0 5px',
      borderRadius: 'var(--radius-xs)',
      boxShadow: 'inset 0 0 0 1px var(--outline)',
      color: 'var(--on-surface-variant)',
      ...style
    }
  }, children || 'Draft');
}
Object.assign(__ds_scope, { Tag });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/chips/Tag.jsx", error: String((e && e.message) || e) }); }

// components/core/Monogram.jsx
try { (() => {
/** 72dp recipe thumbnail: photo, monogram letter on mustard, or placeholder. Also circular member avatar. */
function Monogram({
  letter,
  src,
  size = 72,
  shape = 'tile',
  tone = 'secondary',
  style
}) {
  const circle = shape === 'circle';
  const tones = {
    secondary: ['var(--secondary-container)', 'var(--on-secondary-container)'],
    primary: ['var(--primary-container)', 'var(--on-primary-container)']
  };
  const [bg, fg] = letter ? tones[tone] : ['var(--surface-container-highest)', 'var(--outline)'];
  const fontSize = circle ? Math.round(size * 0.42) : Math.round(size * 30 / 72);
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: size,
      height: size,
      flex: 'none',
      borderRadius: circle ? '50%' : 'var(--radius-sm)',
      background: bg,
      color: fg,
      display: 'grid',
      placeItems: 'center',
      overflow: 'hidden',
      fontFamily: 'var(--font-sans)',
      fontWeight: circle ? 600 : 700,
      fontSize,
      lineHeight: 1,
      ...style
    }
  }, src ? /*#__PURE__*/React.createElement("img", {
    src: src,
    alt: "",
    style: {
      width: '100%',
      height: '100%',
      objectFit: 'cover'
    }
  }) : letter ? letter : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "image",
    size: Math.round(size / 3)
  }));
}
Object.assign(__ds_scope, { Monogram });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Monogram.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Banner.jsx
try { (() => {
/** Calm offline/status banner — surfaceContainerHighest, never red. */
function Banner({
  icon = 'cloud_off',
  children,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "status",
    style: {
      display: 'flex',
      gap: 16,
      alignItems: 'flex-start',
      padding: '14px 16px',
      borderRadius: 'var(--radius-sm)',
      background: 'var(--offline)',
      color: 'var(--on-offline)',
      font: '400 16px/24px var(--font-sans)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 24,
    color: "var(--on-surface-variant)"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      textWrap: 'pretty'
    }
  }, children));
}
Object.assign(__ds_scope, { Banner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Banner.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
/** Basic dialog: surfaceContainerHigh, radius 28, level 3, actions as text buttons on the right. */
function Dialog({
  title,
  children,
  actions,
  open = true,
  onScrim,
  inline,
  style
}) {
  if (!open) return null;
  const box = /*#__PURE__*/React.createElement("div", {
    role: "dialog",
    "aria-modal": "true",
    onClick: e => e.stopPropagation(),
    style: {
      width: 312,
      maxWidth: 'calc(100% - 48px)',
      boxSizing: 'border-box',
      background: 'var(--surface-dialog)',
      borderRadius: 'var(--radius-xl)',
      boxShadow: 'var(--elevation-3)',
      padding: 24,
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: '0 0 16px',
      font: 'var(--type-title-large)'
    }
  }, title), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      textWrap: 'pretty'
    }
  }, children), actions && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'flex-end',
      gap: 8,
      marginTop: 24,
      marginRight: -12
    }
  }, actions));
  return /*#__PURE__*/React.createElement("div", {
    onClick: onScrim,
    style: {
      position: inline ? 'relative' : 'absolute',
      inset: inline ? undefined : 0,
      padding: inline ? 24 : 0,
      borderRadius: inline ? 'var(--radius-md)' : 0,
      background: 'var(--scrim)',
      display: 'grid',
      placeItems: 'center',
      zIndex: 20
    }
  }, box);
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/EmptyState.jsx
try { (() => {
/** Icon 48 in outline · titleMedium · bodyMedium · one tonal action. */
function EmptyState({
  icon = 'list',
  title,
  body,
  action,
  onAction,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      textAlign: 'center',
      padding: '32px 24px',
      gap: 8,
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 48,
    color: "var(--outline)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)',
      color: 'var(--on-surface)',
      marginTop: 8
    }
  }, title), body && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      maxWidth: 280,
      textWrap: 'pretty'
    }
  }, body), action && /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "tonal",
    onClick: onAction,
    style: {
      marginTop: 16
    }
  }, action));
}
Object.assign(__ds_scope, { EmptyState });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/EmptyState.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Menu.jsx
try { (() => {
/** Overflow menu: radius 16, level 2, surfaceContainerHigh. */
function Menu({
  items,
  onSelect,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "menu",
    style: {
      minWidth: 200,
      padding: '8px 0',
      background: 'var(--surface-menu)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--elevation-2)',
      ...style
    }
  }, items.map((it, i) => it.divider ? /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      height: 1,
      margin: '8px 0',
      background: 'var(--outline-variant)'
    }
  }) : /*#__PURE__*/React.createElement("button", {
    key: i,
    role: "menuitem",
    type: "button",
    onClick: () => onSelect && onSelect(it),
    className: "kt-state",
    style: {
      display: 'flex',
      width: '100%',
      alignItems: 'center',
      height: 48,
      padding: '0 16px',
      border: 0,
      background: 'none',
      font: '400 16px/24px var(--font-sans)',
      color: it.destructive ? 'var(--destructive)' : 'var(--on-surface)',
      textAlign: 'left'
    }
  }, it.label)));
}
Object.assign(__ds_scope, { Menu });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Menu.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Snackbar.jsx
try { (() => {
/** inverseSurface snackbar, radius 8, level 2, inversePrimary action. */
function Snackbar({
  message,
  action,
  onAction,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    role: "status",
    style: {
      minHeight: 48,
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      padding: '4px 8px 4px 16px',
      boxSizing: 'border-box',
      background: 'var(--inverse-surface)',
      color: 'var(--on-inverse-surface)',
      borderRadius: 'var(--radius-sm)',
      boxShadow: 'var(--elevation-2)',
      font: 'var(--type-body-medium)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }, message), action && /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onAction,
    className: "kt-state",
    style: {
      height: 40,
      padding: '0 12px',
      border: 0,
      borderRadius: 'var(--radius-full)',
      background: 'none',
      color: 'var(--inverse-primary)',
      font: 'var(--type-label-large)'
    }
  }, action));
}
Object.assign(__ds_scope, { Snackbar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Snackbar.jsx", error: String((e && e.message) || e) }); }

// components/inputs/SearchField.jsx
try { (() => {
/** Stadium search field, 52dp, surfaceContainerHighest. */
function SearchField({
  placeholder = 'Search recipes',
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 12,
      height: 'var(--size-field)',
      padding: '0 20px 0 16px',
      borderRadius: 'var(--radius-full)',
      background: 'var(--surface-container-highest)',
      color: 'var(--on-surface-variant)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "search",
    size: 24
  }), /*#__PURE__*/React.createElement("input", {
    value: value,
    onChange: e => onChange && onChange(e.target.value),
    placeholder: placeholder,
    style: {
      flex: 1,
      minWidth: 0,
      border: 0,
      outline: 0,
      background: 'transparent',
      font: '400 16px/24px var(--font-sans)',
      color: 'var(--on-surface)'
    }
  }));
}
Object.assign(__ds_scope, { SearchField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/inputs/SearchField.jsx", error: String((e && e.message) || e) }); }

// components/inputs/TextField.jsx
try { (() => {
/** Filled 52dp field, radius 8, label above in titleSmall, no underline. Focus = 2dp primary edge. */
function TextField({
  label,
  value,
  defaultValue,
  placeholder,
  helper,
  error,
  disabled,
  multiline,
  onChange,
  type = 'text',
  style
}) {
  const [focus, setFocus] = React.useState(false);
  const ring = error ? 'inset 0 0 0 2px var(--error)' : focus ? 'inset 0 0 0 2px var(--primary)' : 'none';
  const Tag = multiline ? 'textarea' : 'input';
  return /*#__PURE__*/React.createElement("label", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 8,
      opacity: disabled ? 0.38 : 1,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-title-small)',
      color: error ? 'var(--error)' : focus ? 'var(--primary)' : 'var(--on-surface)'
    }
  }, label), /*#__PURE__*/React.createElement(Tag, {
    type: multiline ? undefined : type,
    value: value,
    defaultValue: defaultValue,
    placeholder: placeholder,
    disabled: disabled,
    onChange: e => onChange && onChange(e.target.value),
    onFocus: () => setFocus(true),
    onBlur: () => setFocus(false),
    style: {
      minHeight: 'var(--size-field)',
      height: multiline ? 96 : 'var(--size-field)',
      boxSizing: 'border-box',
      border: 0,
      outline: 0,
      borderRadius: 'var(--radius-sm)',
      background: 'var(--surface-container-highest)',
      boxShadow: ring,
      color: 'var(--on-surface)',
      font: '400 16px/24px var(--font-sans)',
      padding: multiline ? '14px 16px' : '0 16px',
      resize: 'none',
      width: '100%'
    }
  }), (helper || error) && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      gap: 4,
      alignItems: 'center',
      font: 'var(--type-body-small)',
      color: error ? 'var(--error)' : 'var(--on-surface-variant)'
    }
  }, error && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "error",
    size: 16
  }), error || helper));
}
Object.assign(__ds_scope, { TextField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/inputs/TextField.jsx", error: String((e && e.message) || e) }); }

// components/navigation/AppBar.jsx
try { (() => {
/** 64dp top app bar on surface, titleLarge. */
function AppBar({
  title,
  leading,
  onLeading,
  actions,
  style
}) {
  return /*#__PURE__*/React.createElement("header", {
    style: {
      height: 'var(--size-app-bar)',
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      padding: leading ? '0 4px 0 4px' : '0 4px 0 16px',
      background: 'var(--surface)',
      color: 'var(--on-surface)',
      flex: 'none',
      ...style
    }
  }, leading && /*#__PURE__*/React.createElement(__ds_scope.IconButton, {
    icon: leading === 'close' ? 'close' : 'arrow_back_ios_new',
    label: leading,
    onClick: onLeading
  }), /*#__PURE__*/React.createElement("h1", {
    style: {
      flex: 1,
      minWidth: 0,
      margin: 0,
      font: '600 24px/32px var(--font-sans)',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis'
    }
  }, title), actions);
}
Object.assign(__ds_scope, { AppBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/AppBar.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavigationBar.jsx
try { (() => {
const KT_TABS = [{
  value: 'recipes',
  label: 'Recipes',
  icon: 'menu_book'
}, {
  value: 'plan',
  label: 'Plan',
  icon: 'calendar_month'
}, {
  value: 'list',
  label: 'List',
  icon: 'list'
}, {
  value: 'settings',
  label: 'Settings',
  icon: 'tune'
}];
/** 80dp NavigationBar on surfaceContainer. Selected: primary pill, onPrimary filled icon, primary label. */
function NavigationBar({
  items = KT_TABS,
  value,
  onChange,
  style
}) {
  return /*#__PURE__*/React.createElement("nav", {
    style: {
      height: 'var(--size-nav-bar)',
      display: 'flex',
      background: 'var(--surface-nav)',
      flex: 'none',
      ...style
    }
  }, items.map(it => {
    const sel = it.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: it.value,
      type: "button",
      onClick: () => onChange && onChange(it.value),
      style: {
        flex: 1,
        border: 0,
        background: 'none',
        padding: '12px 0 16px',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        gap: 4,
        cursor: 'pointer',
        color: sel ? 'var(--primary)' : 'var(--on-surface-variant)'
      }
    }, /*#__PURE__*/React.createElement("span", {
      className: "kt-state",
      style: {
        width: 64,
        height: 32,
        borderRadius: 'var(--radius-full)',
        display: 'grid',
        placeItems: 'center',
        background: sel ? 'var(--primary)' : 'transparent',
        color: sel ? 'var(--on-primary)' : 'var(--on-surface-variant)',
        transition: 'background var(--duration-medium) var(--ease-emphasized)'
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: it.icon,
      filled: sel,
      size: 24
    })), /*#__PURE__*/React.createElement("span", {
      style: {
        font: 'var(--type-label-medium)',
        fontWeight: sel ? 600 : 500
      }
    }, it.label));
  }));
}
Object.assign(__ds_scope, { KT_TABS, NavigationBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavigationBar.jsx", error: String((e && e.message) || e) }); }

// components/plan/DayCard.jsx
try { (() => {
/** One day of the weekly plan. Today = 2dp primary edge + Today pill. Empty non-today days collapse to 56dp. */
function DayCard({
  label,
  today,
  todayLabel = 'Today',
  addLabel = 'Add meal',
  onAdd,
  dropHint,
  children,
  style
}) {
  const empty = !children || Array.isArray(children) && children.filter(Boolean).length === 0;
  const collapsed = empty && !today;
  const header = /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      flex: collapsed ? 1 : undefined
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-title-small)',
      color: 'var(--on-surface-variant)'
    }
  }, label), today && /*#__PURE__*/React.createElement(__ds_scope.Tag, {
    variant: "today"
  }, todayLabel), dropHint && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-label-medium)',
      color: 'var(--primary)'
    }
  }, dropHint));
  return /*#__PURE__*/React.createElement("section", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      boxShadow: today || dropHint ? 'inset 0 0 0 2px var(--today)' : undefined,
      padding: collapsed ? '4px 4px 4px 16px' : '14px 12px 4px',
      minHeight: collapsed ? 56 : undefined,
      boxSizing: 'border-box',
      display: 'flex',
      flexDirection: collapsed ? 'row' : 'column',
      alignItems: collapsed ? 'center' : 'stretch',
      gap: collapsed ? 0 : 8,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: collapsed ? 0 : '0 4px 4px',
      flex: collapsed ? 1 : undefined
    }
  }, header), !collapsed && children, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      justifyContent: 'flex-end'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    variant: "text",
    icon: "add",
    onClick: onAdd
  }, addLabel)));
}
Object.assign(__ds_scope, { DayCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/plan/DayCard.jsx", error: String((e && e.message) || e) }); }

// components/plan/MealEntry.jsx
try { (() => {
/** Meal inside a day card. Entry = surface fill; leftover = transparent + 1dp dashed outline (derived). */
function MealEntry({
  meta,
  title,
  note,
  leftover,
  recentlyPlanned,
  recentlyLabel = 'Already planned recently',
  draggable = true,
  lifted,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    className: onClick ? 'kt-state' : undefined,
    style: {
      display: 'flex',
      alignItems: 'stretch',
      borderRadius: 'var(--radius-md)',
      background: leftover ? 'transparent' : 'var(--meal-entry)',
      border: leftover ? '1px dashed var(--outline)' : 0,
      boxShadow: lifted ? 'var(--elevation-3)' : undefined,
      color: 'var(--on-surface)',
      ...style
    }
  }, leftover && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'grid',
      placeItems: 'center',
      paddingLeft: 12,
      color: 'var(--leftover)'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "undo",
    size: 24
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      padding: leftover ? '10px 0 10px 12px' : '10px 0 10px 16px',
      display: 'flex',
      flexDirection: 'column',
      gap: 2
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, meta), /*#__PURE__*/React.createElement("span", {
    style: {
      font: note ? '400 17px/24px var(--font-sans)' : 'var(--type-recipe-title)',
      letterSpacing: note ? 0 : 'var(--tracking-recipe-title)',
      textWrap: 'pretty'
    }
  }, title), recentlyPlanned && /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 4,
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      marginTop: 2
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "history",
    size: 16
  }), recentlyLabel)), draggable && /*#__PURE__*/React.createElement("span", {
    "aria-hidden": "true",
    style: {
      width: 40,
      flex: 'none',
      display: 'grid',
      placeItems: 'center',
      color: 'var(--drag-handle)',
      cursor: 'grab'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "drag_indicator",
    size: 20
  })));
}
Object.assign(__ds_scope, { MealEntry });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/plan/MealEntry.jsx", error: String((e && e.message) || e) }); }

// components/recipe/IngredientRow.jsx
try { (() => {
/** Name left, amount right, bodyLarge 18/28, min 48, dashed 6/4 divider. */
function IngredientRow({
  name,
  amount,
  unit,
  optional,
  unmatched,
  flagged,
  note,
  last,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: last ? undefined : 'kt-dash',
    style: {
      minHeight: 48,
      boxSizing: 'border-box',
      display: 'flex',
      flexDirection: 'column',
      justifyContent: 'center',
      padding: flagged ? '10px 0 10px 13px' : '10px 0',
      backgroundColor: flagged ? 'var(--surface-container-low)' : undefined,
      boxShadow: flagged ? 'inset 3px 0 0 var(--review-marker)' : undefined,
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      gap: 16,
      font: 'var(--type-body-large)',
      color: 'var(--on-surface)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1,
      minWidth: 0,
      textWrap: 'pretty'
    }
  }, name, optional && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, " \xB7 ", optional === true ? 'optional' : optional), unmatched && /*#__PURE__*/React.createElement("span", {
    "aria-label": "not matched",
    style: {
      display: 'inline-block',
      width: 12,
      height: 12,
      marginLeft: 8,
      borderRadius: '50%',
      border: '1px dashed var(--unmatched)',
      verticalAlign: '-1px'
    }
  })), amount != null && /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 'none',
      whiteSpace: 'nowrap',
      fontVariantNumeric: 'tabular-nums'
    }
  }, /*#__PURE__*/React.createElement("b", {
    style: {
      fontWeight: 600,
      color: 'var(--primary)'
    }
  }, amount), unit && /*#__PURE__*/React.createElement("span", {
    style: {
      color: 'var(--on-surface-variant)'
    }
  }, " ", unit))), note && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      marginTop: 2
    }
  }, note));
}
Object.assign(__ds_scope, { IngredientRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/recipe/IngredientRow.jsx", error: String((e && e.message) || e) }); }

// components/recipe/RecipeCard.jsx
try { (() => {
function Meta({
  icon,
  children,
  color,
  filled
}) {
  return /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      alignItems: 'center',
      gap: 4,
      whiteSpace: 'nowrap'
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 16,
    filled: filled,
    color: color
  }), children);
}
/** Recipe list card: 72dp thumb/monogram, 700 title, meta items that never split. */
function RecipeCard({
  title,
  servings,
  time,
  rating,
  favorite,
  draft,
  letter,
  src,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    className: onClick ? 'kt-state' : undefined,
    style: {
      display: 'flex',
      gap: 16,
      padding: 12,
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Monogram, {
    letter: letter,
    src: src
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0,
      display: 'flex',
      flexDirection: 'column',
      gap: 6,
      paddingTop: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8,
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      font: 'var(--type-recipe-title)',
      letterSpacing: 'var(--tracking-recipe-title)',
      textWrap: 'pretty'
    }
  }, title), favorite && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "favorite",
    filled: true,
    size: 20,
    color: "var(--favorite)"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexWrap: 'wrap',
      alignItems: 'center',
      columnGap: 12,
      rowGap: 4,
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, draft && /*#__PURE__*/React.createElement(__ds_scope.Tag, null), servings != null && /*#__PURE__*/React.createElement(Meta, {
    icon: "soup_kitchen"
  }, servings), time && /*#__PURE__*/React.createElement(Meta, {
    icon: "schedule"
  }, time), rating != null && /*#__PURE__*/React.createElement(Meta, {
    icon: "star",
    filled: true,
    color: "var(--rating)"
  }, rating))));
}
Object.assign(__ds_scope, { RecipeCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/recipe/RecipeCard.jsx", error: String((e && e.message) || e) }); }

// components/recipe/StatRow.jsx
try { (() => {
/** Servings · Prep · Cook · Rating strip between hairlines. Values in tertiary. */
function StatRow({
  stats,
  rating,
  ratingLabel = 'Rating',
  style
}) {
  const cell = (label, value) => /*#__PURE__*/React.createElement("div", {
    key: label,
    style: {
      flex: 1,
      minWidth: 0,
      display: 'flex',
      flexDirection: 'column',
      gap: 4
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, label), /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-title-medium)',
      color: 'var(--stat-value)',
      minHeight: 24,
      display: 'flex',
      alignItems: 'center'
    }
  }, value));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 12,
      padding: '16px 0',
      borderTop: '1px solid var(--outline-variant)',
      borderBottom: '1px solid var(--outline-variant)',
      ...style
    }
  }, stats.map(s => cell(s.label, s.value)), rating != null && cell(ratingLabel, /*#__PURE__*/React.createElement("span", {
    style: {
      display: 'inline-flex',
      gap: 1
    }
  }, [1, 2, 3, 4, 5].map(n => /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    key: n,
    name: "star",
    size: 16,
    filled: n <= rating,
    color: n <= rating ? 'var(--rating)' : 'var(--outline)'
  })))));
}
Object.assign(__ds_scope, { StatRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/recipe/StatRow.jsx", error: String((e && e.message) || e) }); }

// components/recipe/StepList.jsx
try { (() => {
/** Step timeline: 28dp primaryContainer disc, 16 to text, 24 between steps, 2dp connector 4dp clear of each disc. */
function StepList({
  steps,
  style
}) {
  return /*#__PURE__*/React.createElement("ol", {
    style: {
      listStyle: 'none',
      margin: 0,
      padding: 0,
      display: 'flex',
      flexDirection: 'column',
      ...style
    }
  }, steps.map((s, i) => {
    const last = i === steps.length - 1;
    return /*#__PURE__*/React.createElement("li", {
      key: i,
      style: {
        display: 'flex',
        gap: 16,
        position: 'relative',
        paddingBottom: last ? 0 : 24
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 28,
        height: 28,
        flex: 'none',
        marginTop: 0,
        borderRadius: '50%',
        background: 'var(--today-container)',
        color: 'var(--on-primary-container)',
        font: 'var(--type-label-large)',
        display: 'grid',
        placeItems: 'center'
      }
    }, i + 1), !last && /*#__PURE__*/React.createElement("span", {
      style: {
        position: 'absolute',
        left: 13,
        top: 32,
        bottom: 4,
        width: 2,
        background: 'var(--step-connector)'
      }
    }), /*#__PURE__*/React.createElement("span", {
      style: {
        flex: 1,
        font: 'var(--type-body-large)',
        color: 'var(--on-surface)',
        textWrap: 'pretty',
        marginTop: -1
      }
    }, s));
  }));
}
Object.assign(__ds_scope, { StepList });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/recipe/StepList.jsx", error: String((e && e.message) || e) }); }

// components/settings/ListRow.jsx
try { (() => {
/** Avatar · title · subtitle · trailing chevron/more. Hairline divider below. */
function ListRow({
  letter,
  tone = 'secondary',
  icon,
  title,
  subtitle,
  trailing,
  divider = true,
  onClick,
  onTrailing,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    className: onClick ? 'kt-state' : undefined,
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      minHeight: 72,
      padding: '8px 0',
      boxSizing: 'border-box',
      borderBottom: divider ? '1px solid var(--outline-variant)' : 0,
      color: 'var(--on-surface)',
      ...style
    }
  }, letter && /*#__PURE__*/React.createElement(__ds_scope.Monogram, {
    letter: letter,
    shape: "circle",
    size: 48,
    tone: tone
  }), icon && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 24,
    color: "var(--on-surface-variant)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: '500 16px/24px var(--font-sans)'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, subtitle)), trailing === 'chevron' && /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron_right",
    size: 24,
    color: "var(--on-surface-variant)"
  }), trailing === 'more' && /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "More",
    onClick: e => {
      e.stopPropagation();
      onTrailing && onTrailing();
    },
    className: "kt-state",
    style: {
      width: 48,
      height: 48,
      border: 0,
      background: 'none',
      borderRadius: '50%',
      display: 'grid',
      placeItems: 'center',
      color: 'var(--on-surface-variant)',
      marginRight: -12
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "more_vert"
  })));
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/settings/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/settings/NavRow.jsx
try { (() => {
/** Card-styled row that navigates (icon · title · subtitle · chevron). */
function NavRow({
  icon = 'home',
  title,
  subtitle,
  onClick,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    onClick: onClick,
    className: "kt-state",
    role: "button",
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      padding: '12px 16px',
      minHeight: 72,
      boxSizing: 'border-box',
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 24,
    color: "var(--on-surface-variant)"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, title), subtitle && /*#__PURE__*/React.createElement("div", {
    style: {
      font: '400 16px/24px var(--font-sans)',
      color: 'var(--on-surface-variant)'
    }
  }, subtitle)), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "chevron_right",
    size: 24,
    color: "var(--on-surface-variant)"
  }));
}
Object.assign(__ds_scope, { NavRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/settings/NavRow.jsx", error: String((e && e.message) || e) }); }

// components/settings/ProfileCard.jsx
try { (() => {
/** Signed-in account summary at the top of Settings. */
function ProfileCard({
  name,
  email,
  provider,
  letter,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      padding: 16,
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      color: 'var(--on-surface)',
      ...style
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Monogram, {
    letter: letter || (name || '?')[0],
    shape: "circle",
    size: 56,
    tone: "primary"
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      minWidth: 0
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, name), email && /*#__PURE__*/React.createElement("div", {
    style: {
      font: '400 16px/24px var(--font-sans)',
      color: 'var(--on-surface-variant)'
    }
  }, email), provider && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, provider)));
}
Object.assign(__ds_scope, { ProfileCard });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/settings/ProfileCard.jsx", error: String((e && e.message) || e) }); }

// components/settings/SettingsGroup.jsx
try { (() => {
/** Group header (titleSmall, onSurfaceVariant) + optional card body. 24 between groups. */
function SettingsGroup({
  label,
  children,
  card = true,
  title,
  description,
  style
}) {
  return /*#__PURE__*/React.createElement("section", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      ...style
    }
  }, label && /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: 0,
      padding: '0 4px',
      font: 'var(--type-title-small)',
      color: 'var(--on-surface-variant)'
    }
  }, label), card ? /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: 16,
      display: 'flex',
      flexDirection: 'column',
      gap: 12,
      color: 'var(--on-surface)'
    }
  }, (title || description) && /*#__PURE__*/React.createElement("div", null, title && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, title), description && /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      marginTop: 2
    }
  }, description)), children) : children);
}
Object.assign(__ds_scope, { SettingsGroup });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/settings/SettingsGroup.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/App.jsx
try { (() => {
function App() {
  const {
    Snackbar
  } = window.KitchenTableDesignSystem_abd297;
  const saved = (() => {
    try {
      return JSON.parse(localStorage.getItem('kt-uikit') || '{}');
    } catch (e) {
      return {};
    }
  })();
  const [route, setRoute] = React.useState(saved.route || 'recipes');
  const [theme, setTheme] = React.useState(saved.theme || 'light');
  const [snack, setSnack] = React.useState(null);
  React.useEffect(() => {
    localStorage.setItem('kt-uikit', JSON.stringify({
      route,
      theme
    }));
  }, [route, theme]);
  React.useEffect(() => {
    if (!snack) return;
    const t = setTimeout(() => setSnack(null), 3200);
    return () => clearTimeout(t);
  }, [snack]);
  const say = (m, a) => m && setSnack({
    m,
    a
  });
  const tabOf = {
    recipes: 'recipes',
    detail: 'recipes',
    plan: 'plan',
    list: 'list',
    settings: 'settings',
    household: 'settings'
  };
  const tab = tabOf[route];
  const onTab = setRoute;
  let screen;
  switch (route) {
    case 'signin':
      screen = /*#__PURE__*/React.createElement(SignInScreen, {
        onSignIn: () => setRoute('recipes')
      });
      break;
    case 'detail':
      screen = /*#__PURE__*/React.createElement(RecipeDetailScreen, {
        onBack: () => setRoute('recipes'),
        onSnack: say
      });
      break;
    case 'plan':
      screen = /*#__PURE__*/React.createElement(PlanScreen, {
        tab: tab,
        onTab: onTab,
        onSnack: say
      });
      break;
    case 'list':
      screen = /*#__PURE__*/React.createElement(ListScreen, {
        tab: tab,
        onTab: onTab,
        onSnack: say
      });
      break;
    case 'import':
      screen = /*#__PURE__*/React.createElement(ReviewImportScreen, {
        onClose: () => setRoute('recipes'),
        onSave: () => {
          setRoute('recipes');
          say('Recipe saved.');
        }
      });
      break;
    case 'settings':
      screen = /*#__PURE__*/React.createElement(SettingsScreen, {
        tab: tab,
        onTab: onTab,
        theme: theme,
        onTheme: setTheme,
        onHousehold: () => setRoute('household'),
        onSignOut: () => setRoute('signin')
      });
      break;
    case 'household':
      screen = /*#__PURE__*/React.createElement(HouseholdScreen, {
        tab: tab,
        onTab: onTab,
        onBack: () => setRoute('settings'),
        onSnack: say
      });
      break;
    default:
      screen = /*#__PURE__*/React.createElement(RecipesScreen, {
        tab: tab,
        onTab: onTab,
        onOpen: () => setRoute('detail')
      });
  }
  const jump = [['signin', 'Sign in'], ['recipes', 'Recipes'], ['detail', 'Recipe'], ['plan', 'Plan'], ['list', 'List'], ['import', 'Review import'], ['settings', 'Settings'], ['household', 'Household']];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 32,
      padding: 24,
      boxSizing: 'border-box',
      background: '#d9d3ca',
      flexWrap: 'wrap'
    }
  }, /*#__PURE__*/React.createElement("div", {
    "data-theme": theme,
    "data-screen-label": route,
    style: {
      width: 412,
      height: 892,
      position: 'relative',
      overflow: 'hidden',
      borderRadius: 32,
      background: 'var(--surface)',
      boxShadow: '0 0 0 10px #1f190f, 0 24px 60px rgba(0,0,0,.25)',
      fontFamily: 'var(--font-sans)'
    }
  }, screen, snack && /*#__PURE__*/React.createElement(Snackbar, {
    message: snack.m,
    action: snack.a,
    onAction: () => setSnack(null),
    style: {
      position: 'absolute',
      left: 12,
      right: 12,
      bottom: tab && route !== 'detail' ? 92 : 16,
      zIndex: 30
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 4,
      font: '500 13px/18px var(--font-sans)'
    }
  }, jump.map(([r, l]) => /*#__PURE__*/React.createElement("button", {
    key: r,
    onClick: () => setRoute(r),
    style: {
      textAlign: 'left',
      border: 0,
      background: route === r ? '#1f190f' : 'transparent',
      color: route === r ? '#fff7ec' : '#1f190f',
      padding: '6px 12px',
      borderRadius: 999,
      cursor: 'pointer',
      font: 'inherit'
    }
  }, l)), /*#__PURE__*/React.createElement("button", {
    onClick: () => setTheme(theme === 'light' ? 'dark' : 'light'),
    style: {
      marginTop: 8,
      textAlign: 'left',
      border: '1px solid #1f190f',
      background: 'transparent',
      padding: '6px 12px',
      borderRadius: 999,
      cursor: 'pointer',
      font: 'inherit',
      color: '#1f190f'
    }
  }, theme === 'light' ? 'Dark theme' : 'Light theme')));
}
ReactDOM.createRoot(document.getElementById('root')).render(/*#__PURE__*/React.createElement(App, null));
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/App.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/HouseholdScreen.jsx
try { (() => {
function HouseholdScreen({
  tab,
  onTab,
  onBack,
  onSnack
}) {
  const {
    IconButton,
    ListRow,
    Button,
    Dialog
  } = window.KitchenTableDesignSystem_abd297;
  const [confirm, setConfirm] = React.useState(false);
  return /*#__PURE__*/React.createElement(Screen, {
    title: "Household",
    leading: "back",
    onLeading: onBack,
    tab: tab,
    onTab: onTab,
    overlay: confirm && /*#__PURE__*/React.createElement(Dialog, {
      title: "Leave household?",
      onScrim: () => setConfirm(false),
      actions: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Button, {
        variant: "text",
        onClick: () => setConfirm(false)
      }, "Cancel"), /*#__PURE__*/React.createElement(Button, {
        variant: "destructive",
        onClick: () => {
          setConfirm(false);
          onBack();
        }
      }, "Leave"))
    }, "You'll lose access to Kod Mire's recipes, meal plans and shopping lists. Mira can invite you again.")
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '8px 16px 24px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'flex-start'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-headline-small)',
      letterSpacing: 'var(--tracking-headline-small)'
    }
  }, "Kod Mire"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: '400 16px/24px var(--font-sans)',
      color: 'var(--on-surface-variant)',
      marginTop: 4
    }
  }, "2 members")), /*#__PURE__*/React.createElement(IconButton, {
    icon: "edit",
    label: "Rename"
  })), /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: '28px 0 8px',
      font: 'var(--type-title-medium)'
    }
  }, "Members"), /*#__PURE__*/React.createElement(ListRow, {
    letter: "M",
    tone: "primary",
    title: "Mira Jovanovi\u0107",
    subtitle: "Owner"
  }), /*#__PURE__*/React.createElement(ListRow, {
    letter: "L",
    title: "Luka Jovanovi\u0107",
    subtitle: "Member \xB7 you",
    trailing: "more"
  }), /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: '28px 0 12px',
      font: 'var(--type-title-medium)'
    }
  }, "Invite codes"), /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: '16px 16px 12px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: '500 28px/36px var(--font-mono)',
      letterSpacing: 4
    }
  }, "KT4-9PX"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      margin: '2px 0 12px'
    }
  }, "Expires in 6 days"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 8
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "tonal",
    icon: "content_copy",
    onClick: () => onSnack('Code copied.')
  }, "Copy code"), /*#__PURE__*/React.createElement(Button, {
    variant: "destructive"
  }, "Revoke"))), /*#__PURE__*/React.createElement(Button, {
    variant: "outlined",
    icon: "add",
    style: {
      marginTop: 12
    }
  }, "New invite code"), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 1,
      background: 'var(--outline-variant)',
      margin: '24px 0 8px'
    }
  }), /*#__PURE__*/React.createElement(Button, {
    variant: "destructive",
    icon: "logout",
    style: {
      paddingLeft: 4
    },
    onClick: () => setConfirm(true)
  }, "Leave household")));
}
window.HouseholdScreen = HouseholdScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/HouseholdScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/ListScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function ListScreen({
  tab,
  onTab,
  onSnack
}) {
  const {
    IconButton,
    Banner,
    SegmentedButton,
    Tag,
    IngredientRow,
    Icon
  } = window.KitchenTableDesignSystem_abd297;
  const D = window.KT_DATA;
  const [range, setRange] = React.useState('this');
  const [open, setOpen] = React.useState(false);
  return /*#__PURE__*/React.createElement(Screen, {
    title: "List",
    tab: tab,
    onTab: onTab,
    actions: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(IconButton, {
      icon: "refresh",
      label: "Regenerate"
    }), /*#__PURE__*/React.createElement(IconButton, {
      icon: "content_copy",
      label: "Copy list",
      onClick: () => onSnack('List copied.', 'Undo')
    }))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 16px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(Banner, null, "You're offline \u2014 showing saved copies. Changes won't save."), /*#__PURE__*/React.createElement(SegmentedButton, {
    options: [{
      value: 'this',
      label: 'This week'
    }, {
      value: 'next',
      label: 'Next'
    }, {
      value: 'pick',
      label: 'Pick dates'
    }],
    value: range,
    onChange: setRange
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, "Generated Sep 25 for Sep 28 \u2013 Oct 4"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Tag, {
    variant: "docLanguage",
    code: "SR"
  }, "This list is in Serbian")), /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: '4px 16px 8px'
    }
  }, D.list.map(s => /*#__PURE__*/React.createElement("div", {
    key: s.aisle
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-small)',
      fontSize: 15,
      padding: '16px 0 0'
    }
  }, s.aisle), s.items.map((it, i) => /*#__PURE__*/React.createElement(IngredientRow, _extends({
    key: i
  }, it, {
    last: i === s.items.length - 1
  })))))), /*#__PURE__*/React.createElement("div", {
    onClick: () => setOpen(!open),
    className: "kt-state",
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: '12px 16px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-small)',
      fontSize: 15
    }
  }, "Probably have (", D.staples.length, ")"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, "Cupboard staples")), /*#__PURE__*/React.createElement(Icon, {
    name: open ? 'expand_less' : 'expand_more',
    color: "var(--on-surface-variant)"
  })), open && /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 8
    }
  }, D.staples.map((n, i) => /*#__PURE__*/React.createElement(IngredientRow, {
    key: n,
    name: n,
    last: i === D.staples.length - 1
  }))))));
}
window.ListScreen = ListScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/ListScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/PlanScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function PlanScreen({
  tab,
  onTab,
  onSnack
}) {
  const {
    SegmentedButton,
    IconButton,
    DayCard,
    MealEntry
  } = window.KitchenTableDesignSystem_abd297;
  const D = window.KT_DATA;
  const [mode, setMode] = React.useState('week');
  const days = mode === 'week' ? D.week : D.week.filter(d => d.today);
  return /*#__PURE__*/React.createElement(Screen, {
    title: "Plan",
    tab: tab,
    onTab: onTab
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 16px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(SegmentedButton, {
    options: [{
      value: 'week',
      label: 'This week'
    }, {
      value: 'today',
      label: 'Today'
    }],
    value: mode,
    onChange: setMode
  }), mode === 'week' && /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 4px'
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_left",
    label: "Previous week"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, "Sep 14 \u2013 20"), /*#__PURE__*/React.createElement(IconButton, {
    icon: "chevron_right",
    label: "Next week"
  })), days.map(d => /*#__PURE__*/React.createElement(DayCard, {
    key: d.label,
    label: d.label,
    today: d.today,
    onAdd: () => onSnack('Add meal opens the 4-slot sheet.')
  }, d.meals.map((m, i) => /*#__PURE__*/React.createElement(MealEntry, _extends({
    key: i
  }, m)))))));
}
window.PlanScreen = PlanScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/PlanScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/RecipeDetailScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function RecipeDetailScreen({
  onBack,
  onSnack
}) {
  const {
    IconButton,
    Icon,
    Tag,
    StatRow,
    IngredientRow,
    StepList,
    Menu
  } = window.KitchenTableDesignSystem_abd297;
  const R = window.KT_DATA.peppers;
  const [fav, setFav] = React.useState(true);
  const [menu, setMenu] = React.useState(false);
  return /*#__PURE__*/React.createElement(Screen, {
    bar: false,
    overlay: menu && /*#__PURE__*/React.createElement("div", {
      onClick: () => setMenu(false),
      style: {
        position: 'absolute',
        inset: 0,
        zIndex: 10
      }
    }, /*#__PURE__*/React.createElement(Menu, {
      style: {
        position: 'absolute',
        top: 64,
        right: 12
      },
      items: [{
        label: 'Add to plan…'
      }, {
        label: 'Review translation'
      }, {
        divider: true
      }, {
        label: 'Delete recipe',
        destructive: true
      }],
      onSelect: it => {
        setMenu(false);
        onSnack(it.label === 'Add to plan…' ? 'Added to Wed, Sep 16.' : null);
      }
    }))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      height: 184,
      background: 'var(--surface-container-highest)',
      position: 'relative',
      display: 'grid',
      placeItems: 'center',
      color: 'var(--outline)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "image",
    size: 32
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      top: 12,
      left: 12,
      right: 12,
      display: 'flex',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement(IconButton, {
    icon: "arrow_back_ios_new",
    variant: "onImage",
    size: 40,
    onClick: onBack,
    label: "Back"
  }), /*#__PURE__*/React.createElement("span", {
    style: {
      flex: 1
    }
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "favorite",
    filled: fav,
    color: "var(--favorite)",
    variant: "onImage",
    size: 40,
    onClick: () => setFav(!fav),
    label: "Favourite"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "edit",
    variant: "onImage",
    size: 40,
    label: "Edit"
  }), /*#__PURE__*/React.createElement(IconButton, {
    icon: "more_vert",
    variant: "onImage",
    size: 40,
    onClick: () => setMenu(true),
    label: "More"
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '16px 16px 32px'
    }
  }, /*#__PURE__*/React.createElement(Tag, {
    variant: "machineTranslation"
  }), /*#__PURE__*/React.createElement("h1", {
    style: {
      margin: '12px 0 8px',
      font: 'var(--type-headline-small)',
      letterSpacing: 'var(--tracking-headline-small)'
    }
  }, R.title), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '0 0 20px',
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)',
      textWrap: 'pretty'
    }
  }, R.description), /*#__PURE__*/React.createElement(StatRow, {
    stats: [{
      label: 'Servings',
      value: '4'
    }, {
      label: 'Prep',
      value: '30 min'
    }, {
      label: 'Cook',
      value: '1 h'
    }],
    rating: 4
  }), /*#__PURE__*/React.createElement(SectionTitle, {
    trailing: "for 4 servings"
  }, "Ingredients"), R.ingredients.map((g, i) => /*#__PURE__*/React.createElement(IngredientRow, _extends({
    key: i
  }, g, {
    last: i === R.ingredients.length - 1
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 8
    }
  }), /*#__PURE__*/React.createElement(SectionTitle, null, "Steps"), /*#__PURE__*/React.createElement(StepList, {
    steps: R.steps,
    style: {
      marginTop: 16
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 32,
      paddingTop: 12,
      borderTop: '1px solid var(--outline-variant)',
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      font: 'var(--type-body-small)',
      color: 'var(--on-surface-variant)'
    }
  }, /*#__PURE__*/React.createElement(Icon, {
    name: "link",
    size: 16
  }), "Imported from a link \xB7 ", /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "[SOURCE]"))));
}
window.RecipeDetailScreen = RecipeDetailScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/RecipeDetailScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/RecipesScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function RecipesScreen({
  onOpen,
  tab,
  onTab
}) {
  const {
    IconButton,
    SearchField,
    FilterRow,
    RecipeCard,
    EmptyState
  } = window.KitchenTableDesignSystem_abd297;
  const D = window.KT_DATA;
  const [sel, setSel] = React.useState(['Favorites', 'Lenten']);
  const [q, setQ] = React.useState('');
  const toggle = f => setSel(s => s.includes(f) ? s.filter(x => x !== f) : [...s, f]);
  const shown = D.recipes.filter(r => sel.every(f => r.tags.includes(f)) && r.title.toLowerCase().includes(q.toLowerCase()));
  return /*#__PURE__*/React.createElement(Screen, {
    title: "Recipes",
    actions: /*#__PURE__*/React.createElement(IconButton, {
      icon: "add",
      label: "New recipe"
    }),
    tab: tab,
    onTab: onTab
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 16px 12px'
    }
  }, /*#__PURE__*/React.createElement(SearchField, {
    value: q,
    onChange: setQ
  })), /*#__PURE__*/React.createElement(FilterRow, {
    filters: D.filters,
    selected: sel,
    onToggle: toggle,
    onClear: () => setSel([])
  }), shown.length ? /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '16px 16px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, shown.length, " recipes"), shown.map(r => /*#__PURE__*/React.createElement(RecipeCard, _extends({
    key: r.id
  }, r, {
    onClick: () => onOpen(r)
  })))) : /*#__PURE__*/React.createElement("div", {
    style: {
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)'
    }
  }, /*#__PURE__*/React.createElement(EmptyState, {
    icon: "search_off",
    title: "No recipes match that.",
    body: "Try removing a filter to see more recipes.",
    action: "Clear filters",
    onAction: () => {
      setSel([]);
      setQ('');
    }
  }))));
}
window.RecipesScreen = RecipesScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/RecipesScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/ReviewImportScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function ReviewImportScreen({
  onClose,
  onSave
}) {
  const {
    TextField,
    IngredientRow,
    Button,
    Icon
  } = window.KitchenTableDesignSystem_abd297;
  const D = window.KT_DATA;
  return /*#__PURE__*/React.createElement(Screen, {
    title: "Review import",
    leading: "close",
    onLeading: onClose,
    footer: /*#__PURE__*/React.createElement("div", {
      style: {
        display: 'flex',
        gap: 12,
        padding: '12px 16px 16px',
        borderTop: '1px solid var(--outline-variant)',
        background: 'var(--surface)'
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "outlined",
      style: {
        flex: 1
      },
      onClick: onClose
    }, "Discard this import"), /*#__PURE__*/React.createElement(Button, {
      style: {
        flex: 1
      },
      onClick: onSave
    }, "Save recipe"))
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 16px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, "9 of 11 matched"), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 4,
      borderRadius: 2,
      background: 'var(--surface-container-highest)',
      margin: '12px 0'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: '82%',
      height: '100%',
      borderRadius: 2,
      background: 'var(--primary)'
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      gap: 8,
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 3,
      height: 16,
      background: 'var(--review-marker)',
      borderRadius: 1
    }
  }), "2 worth a look before saving")), /*#__PURE__*/React.createElement(TextField, {
    label: "Title",
    defaultValue: "Sauerkraut sarma"
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: '0 0 4px',
      font: 'var(--type-title-medium)'
    }
  }, "Ingredients"), D.imported.map((g, i) => /*#__PURE__*/React.createElement(IngredientRow, _extends({
    key: i
  }, g, {
    style: {
      paddingLeft: g.flagged ? 13 : 12,
      paddingRight: 12
    },
    last: i === D.imported.length - 1
  }))), /*#__PURE__*/React.createElement(Button, {
    variant: "text",
    icon: "add",
    style: {
      marginTop: 8
    }
  }, "Add ingredient")), /*#__PURE__*/React.createElement("div", {
    className: "kt-state",
    style: {
      display: 'flex',
      alignItems: 'center',
      background: 'var(--card)',
      borderRadius: 'var(--radius-md)',
      padding: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-title-medium)'
    }
  }, "Method"), /*#__PURE__*/React.createElement("div", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, "6 steps")), /*#__PURE__*/React.createElement(Icon, {
    name: "chevron_right",
    color: "var(--on-surface-variant)"
  }))));
}
window.ReviewImportScreen = ReviewImportScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/ReviewImportScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/SettingsScreen.jsx
try { (() => {
function SettingsScreen({
  tab,
  onTab,
  theme,
  onTheme,
  onHousehold,
  onSignOut
}) {
  const {
    ProfileCard,
    SettingsGroup,
    SegmentedButton,
    NavRow,
    Button
  } = window.KitchenTableDesignSystem_abd297;
  const [lang, setLang] = React.useState('en');
  return /*#__PURE__*/React.createElement(Screen, {
    title: "Settings",
    tab: tab,
    onTab: onTab
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '4px 16px 24px',
      display: 'flex',
      flexDirection: 'column',
      gap: 24
    }
  }, /*#__PURE__*/React.createElement(ProfileCard, {
    name: "Luka Jovanovi\u0107",
    email: "luka@example.com",
    provider: "Signed in with Google"
  }), /*#__PURE__*/React.createElement(SettingsGroup, {
    label: "Appearance",
    title: "Theme",
    description: "Applies to this app only, whatever your phone uses."
  }, /*#__PURE__*/React.createElement(SegmentedButton, {
    options: [{
      value: 'light',
      label: 'Light',
      icon: 'light_mode'
    }, {
      value: 'dark',
      label: 'Dark',
      icon: 'dark_mode'
    }],
    value: theme,
    onChange: onTheme
  })), /*#__PURE__*/React.createElement(SettingsGroup, {
    label: "Language"
  }, /*#__PURE__*/React.createElement(SegmentedButton, {
    options: [{
      value: 'sr',
      label: 'Srpski'
    }, {
      value: 'en',
      label: 'English'
    }],
    value: lang,
    onChange: setLang
  })), /*#__PURE__*/React.createElement(SettingsGroup, {
    label: "Household",
    card: false
  }, /*#__PURE__*/React.createElement(NavRow, {
    title: "Kod Mire",
    subtitle: "2 members",
    onClick: onHousehold
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 1,
      background: 'var(--outline-variant)'
    }
  }), /*#__PURE__*/React.createElement(SettingsGroup, {
    label: "Account",
    card: false,
    style: {
      marginTop: -8
    }
  }, /*#__PURE__*/React.createElement(Button, {
    variant: "neutral",
    icon: "login",
    fullWidth: true,
    onClick: onSignOut
  }, "Sign out"))));
}
window.SettingsScreen = SettingsScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/Shell.jsx
try { (() => {
const {
  AppBar,
  NavigationBar
} = window.KitchenTableDesignSystem_abd297;
/** Screen = optional app bar + scrolling body + optional nav bar + overlay slot. */
function Screen({
  title,
  leading,
  onLeading,
  actions,
  tab,
  onTab,
  footer,
  children,
  overlay,
  bodyStyle,
  bar = true
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      display: 'flex',
      flexDirection: 'column',
      background: 'var(--surface)',
      color: 'var(--on-surface)'
    }
  }, bar && /*#__PURE__*/React.createElement(AppBar, {
    title: title,
    leading: leading,
    onLeading: onLeading,
    actions: actions
  }), /*#__PURE__*/React.createElement("div", {
    className: "kt-noscroll",
    style: {
      flex: 1,
      overflowY: 'auto',
      ...bodyStyle
    }
  }, children), footer, tab && /*#__PURE__*/React.createElement(NavigationBar, {
    value: tab,
    onChange: onTab
  }), overlay);
}
function SectionTitle({
  children,
  trailing
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'baseline',
      justifyContent: 'space-between',
      margin: '24px 0 4px'
    }
  }, /*#__PURE__*/React.createElement("h2", {
    style: {
      margin: 0,
      font: 'var(--type-title-medium)'
    }
  }, children), trailing && /*#__PURE__*/React.createElement("span", {
    style: {
      font: 'var(--type-body-medium)',
      color: 'var(--on-surface-variant)'
    }
  }, trailing));
}
Object.assign(window, {
  Screen,
  SectionTitle
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/Shell.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/SignInScreen.jsx
try { (() => {
function SignInScreen({
  onSignIn
}) {
  const {
    Button
  } = window.KitchenTableDesignSystem_abd297;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      background: 'var(--surface)',
      display: 'flex',
      flexDirection: 'column',
      padding: '0 24px 32px'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      textAlign: 'center'
    }
  }, /*#__PURE__*/React.createElement("img", {
    src: "../../assets/illustrations/recipe-card.png",
    alt: "",
    style: {
      width: 176,
      marginBottom: 40
    }
  }), /*#__PURE__*/React.createElement("img", {
    src: document.querySelector('[data-theme="dark"]') ? '../../assets/logo/lockup-en-dark.svg' : '../../assets/logo/lockup-en-light.svg',
    alt: "Kitchen Table",
    style: {
      height: 48
    }
  }), /*#__PURE__*/React.createElement("p", {
    style: {
      margin: '16px 16px 0',
      font: '400 18px/28px var(--font-sans)',
      color: 'var(--on-surface-variant)',
      textWrap: 'pretty'
    }
  }, "The recipes your home already cooks \u2014 for the whole household, in both languages.")), /*#__PURE__*/React.createElement(Button, {
    variant: "google",
    fullWidth: true,
    onClick: onSignIn
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 24,
      height: 24,
      border: '1px dashed var(--outline)',
      borderRadius: 2,
      display: 'grid',
      placeItems: 'center',
      font: 'var(--type-label-medium)',
      color: 'var(--outline)'
    }
  }, "G"), "Sign in with Google"));
}
window.SignInScreen = SignInScreen;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/SignInScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/app/data.js
try { (() => {
window.KT_DATA = {
  recipes: [{
    id: 'prebranac',
    title: 'Baked beans prebranac',
    servings: '6 servings',
    time: '2 h 15 min',
    rating: 5,
    favorite: true,
    tags: ['Favorites', 'Lenten']
  }, {
    id: 'sarma',
    title: 'Lenten sarma',
    letter: 'L',
    servings: '8 servings',
    time: '3 h',
    rating: 4,
    favorite: true,
    tags: ['Favorites', 'Lenten']
  }, {
    id: 'peppers',
    title: 'Stuffed peppers',
    servings: '4 servings',
    time: '1 h 30 min',
    rating: 4,
    tags: ['Feast days']
  }, {
    id: 'gibanica',
    title: "Grandma Ljubica's gibanica",
    letter: 'G',
    draft: true,
    servings: '12 servings',
    time: '1 h 15 min',
    rating: 4,
    favorite: true,
    tags: ['Favorites', 'Cakes', 'Feast days']
  }, {
    id: 'proja',
    title: 'Cornbread with cheese',
    letter: 'C',
    servings: '4 servings',
    time: '50 min',
    rating: 5,
    tags: []
  }],
  filters: ['Favorites', 'Lenten', 'Cakes', 'Feast days'],
  peppers: {
    title: 'Stuffed peppers',
    description: 'A summer dish from Vojvodina — peppers stuffed with meat and rice, simmered in tomato sauce.',
    ingredients: [{
      name: 'bell peppers',
      amount: '8'
    }, {
      name: 'minced meat',
      amount: '½',
      unit: 'kg'
    }, {
      name: 'rice',
      amount: '½',
      unit: 'cup'
    }, {
      name: 'onion',
      amount: '1'
    }, {
      name: 'sweet paprika',
      optional: true,
      amount: '1',
      unit: 'tsp'
    }, {
      name: 'tomato purée',
      amount: '800',
      unit: 'g'
    }, {
      name: 'salt, to taste'
    }, {
      name: 'prstohvat bibera iz bakine vodenice',
      unmatched: true
    }],
    steps: ['Cut the tops off the peppers and remove the seeds.', 'Fry the onion in oil until translucent, then add the meat, rice and spices.', 'Stuff the peppers, stand them upright in a pot and cover with tomato purée thinned with water.', 'Simmer covered for about an hour, until the peppers are soft.']
  },
  week: [{
    label: 'Mon, Sep 14',
    meals: [{
      meta: 'Lunch · 6 servings',
      title: 'Baked beans prebranac'
    }, {
      meta: 'Dinner · note',
      title: "Dinner at Mum's",
      note: true
    }]
  }, {
    label: 'Tue, Sep 15',
    today: true,
    meals: [{
      meta: 'Breakfast · 4 servings',
      title: 'Cornbread with cheese'
    }, {
      meta: 'Lunch · 8 servings',
      title: 'Sarma'
    }, {
      meta: 'Dinner · from Monday',
      title: 'Leftovers: Baked beans prebranac',
      leftover: true
    }]
  }, {
    label: 'Wed, Sep 16',
    meals: [{
      meta: 'Lunch · 4 servings',
      title: 'Stuffed peppers',
      recentlyPlanned: true
    }]
  }, {
    label: 'Thu, Sep 17',
    meals: []
  }, {
    label: 'Fri, Sep 18',
    meals: [{
      meta: 'Dinner · 4 servings',
      title: 'Fish soup'
    }]
  }, {
    label: 'Sat, Sep 19',
    meals: []
  }, {
    label: 'Sun, Sep 20',
    meals: []
  }],
  list: [{
    aisle: 'Povrće',
    items: [{
      name: 'babura paprika',
      amount: '8'
    }, {
      name: 'crni luk',
      amount: '3',
      unit: 'glavice'
    }, {
      name: 'kiseli kupus',
      amount: '1',
      unit: 'kg'
    }]
  }, {
    aisle: 'Meso',
    items: [{
      name: 'mešano mleveno meso',
      amount: '1,5',
      unit: 'kg'
    }, {
      name: 'dimljena slanina',
      amount: '200',
      unit: 'g'
    }]
  }, {
    aisle: 'Mlečni proizvodi',
    items: [{
      name: 'beli sir',
      amount: '500',
      unit: 'g'
    }, {
      name: 'jogurt',
      amount: '1',
      unit: 'l'
    }]
  }, {
    aisle: 'Ostava',
    items: [{
      name: 'pirinač',
      amount: '300',
      unit: 'g'
    }, {
      name: 'paradajz pire',
      amount: '800',
      unit: 'g'
    }, {
      name: 'so, po ukusu'
    }]
  }],
  staples: ['so', 'ulje', 'brašno', 'biber', 'aleva paprika', 'šećer'],
  imported: [{
    name: 'sauerkraut',
    amount: '1',
    unit: 'head',
    note: '→ sauerkraut'
  }, {
    name: 'mixed minced meat',
    amount: '1',
    unit: 'kg',
    note: '→ minced meat, mixed'
  }, {
    name: 'rice',
    amount: '2',
    unit: 'handfuls',
    note: '→ rice · unit “handful” not recognised',
    flagged: true
  }, {
    name: 'dry-cured bacon',
    amount: '200',
    unit: 'g',
    note: '→ bacon, smoked'
  }, {
    name: 'Vegeta, to taste',
    note: 'Not matched to an ingredient',
    flagged: true,
    unmatched: true
  }, {
    name: 'onion',
    amount: '1',
    note: '→ onion'
  }]
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/app/data.js", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.SegmentedButton = __ds_scope.SegmentedButton;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.FilterRow = __ds_scope.FilterRow;

__ds_ns.Tag = __ds_scope.Tag;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Monogram = __ds_scope.Monogram;

__ds_ns.Banner = __ds_scope.Banner;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.EmptyState = __ds_scope.EmptyState;

__ds_ns.Menu = __ds_scope.Menu;

__ds_ns.Snackbar = __ds_scope.Snackbar;

__ds_ns.SearchField = __ds_scope.SearchField;

__ds_ns.TextField = __ds_scope.TextField;

__ds_ns.AppBar = __ds_scope.AppBar;

__ds_ns.KT_TABS = __ds_scope.KT_TABS;

__ds_ns.NavigationBar = __ds_scope.NavigationBar;

__ds_ns.DayCard = __ds_scope.DayCard;

__ds_ns.MealEntry = __ds_scope.MealEntry;

__ds_ns.IngredientRow = __ds_scope.IngredientRow;

__ds_ns.RecipeCard = __ds_scope.RecipeCard;

__ds_ns.StatRow = __ds_scope.StatRow;

__ds_ns.StepList = __ds_scope.StepList;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.NavRow = __ds_scope.NavRow;

__ds_ns.ProfileCard = __ds_scope.ProfileCard;

__ds_ns.SettingsGroup = __ds_scope.SettingsGroup;

})();
