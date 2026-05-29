# OpenCode-Inspired Design System

A professional, terminal/developer-tool aesthetic design system with glass effects and a refined dark palette.

## Color Palette

### Backgrounds (Layered Dark)
- `--bg-base`: #0a0a0f (deepest background)
- `--bg-elevated`: #12121a (elevated surfaces)
- `--bg-surface`: #1a1a24 (cards, panels)
- `--bg-hover`: #22222e (hover states)

### Glass Effects
- `--glass-bg`: rgba(255, 255, 255, 0.04)
- `--glass-border`: rgba(255, 255, 255, 0.08)
- `--glass-highlight`: rgba(255, 255, 255, 0.12)

### Primary (Indigo/Slate)
- `--primary-50`: rgba(99, 102, 241, 0.1)
- `--primary-100`: rgba(99, 102, 241, 0.2)
- `--primary-200`: rgba(99, 102, 241, 0.3)
- `--primary-300`: rgba(99, 102, 241, 0.5)
- `--primary-400`: rgba(99, 102, 241, 0.7)
- `--primary-500`: #6366f1
- `--primary-600`: #4f46e5
- `--primary-700`: #4338ca

### Accent (Cyan)
- `--accent-400`: #22d3ee
- `--accent-500`: #06b6d4
- `--accent-600`: #0891b2

### Semantic Colors
- **Success**: --success-400: #34d399, --success-500: #10b981
- **Warning**: --warning-400: #fbbf24, --warning-500: #f59e0b
- **Error**: --error-400: #87171, --error-500: #ef4444

### Category Colors (for biomedical domains)
Each category has a subtle background and border:
- Disease: rose tones (rgba(248, 113, 113, ...))
- Treatment: emerald tones (rgba(52, 211, 153, ...))
- Anatomy: blue tones (rgba(96, 165, 250, ...))
- Chemical: amber tones (rgba(251, 191, 36, ...))
- Method: violet tones (rgba(167, 139, 250, ...))
- Population: cyan tones (rgba(34, 211, 238, ...))
- Outcome: indigo tones (rgba(99, 102, 241, ...))
- General: slate tones (rgba(148, 163, 184, ...))

### Text Colors
- `--text-primary`: rgba(255, 255, 255, 0.95)
- `--text-secondary`: rgba(255, 255, 255, 0.7)
- `--text-muted`: rgba(255, 255, 255, 0.4)
- `--text-disabled`: rgba(255, 255, 255, 0.25)

## Typography

### Font Families
- **Sans**: Inter (system-ui fallback)
- **Mono**: JetBrains Mono (Fira Code fallback)

### Type Scale
- Display: 3xl-4xl, bold
- Headings: text-lg to text-xl, semibold
- Body: text-sm to text-base, regular
- Labels: text-xs, medium/uppercase tracking

## Spacing

Uses standard scale: 0.25rem (1) to 2rem (8)

## Border Radius
- `--radius-sm`: 0.375rem
- `--radius-md`: 0.5rem
- `--radius-lg`: 0.75rem
- `--radius-xl`: 1rem

## Animation Timings
- `--transition-fast`: 150ms
- `--transition-normal`: 200ms
- `--transition-slow`: 300ms

## Component Classes

### Glass Card
```css
.glass-card {
  background: var(--glass-bg);
  backdrop-filter: blur(16px);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-xl);
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.4), inset 0 1px 0 var(--glass-highlight);
}
```

### Glass Input
```css
.glass-input {
  background: rgba(255, 255, 255, 0.03);
  backdrop-filter: blur(8px);
  border: 1px solid var(--glass-border);
  border-radius: var(--radius-lg);
  /* Focus: border-color: var(--primary-500) with glow */
}
```

### Glass Button (Primary)
```css
.glass-button {
  background: linear-gradient(135deg, var(--primary-600) 0%, var(--primary-700) 100%);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: var(--radius-lg);
  /* Hover: translateY(-1px), increased shadow */
}
```

### Term Chip
- Pill-shaped with category-specific colors
- Selected state shows checkmark and gradient background

### Query Display
- Monospace font (JetBrains Mono)
- Dark background with glass border
- Cyan accent text

## Animations
- `fadeIn`: opacity 0→1, translateY(8px→0), --transition-slow
- `pulseGlow`: subtle box-shadow pulse for glowing elements

## Usage

Import fonts in globals.css:
```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');
```

Apply glass-card class to containers, glass-input to form fields, glass-button to buttons.

## Design Principles
1. Layered depth with subtle transparency
2. Refined glassmorphism with blur effects
3. High contrast text on dark backgrounds
4. Accent colors for semantic meaning (AND=blue, OR=amber)
5. Consistent spacing and border radius
6. Smooth micro-interactions