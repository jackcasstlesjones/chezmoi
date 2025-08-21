# AGS v3 Development Notes

## Working Configuration

- **AGS Version**: 3.0.0
- **Platform**: Hyprland on Linux
- **Audio**: PipeWire

## Critical Mistakes to Avoid

### 1. Import Syntax

❌ **Wrong**:

```typescript
import { App, Astal, Gtk, Gdk } from "astal/gtk3";
import { Variable, bind } from "astal";
import Audio from "ags/service/audio";
```

✅ **Correct**:

```typescript
import app from "ags/gtk3/app";
import { createState } from "ags";
// Audio service may not be available - use external commands instead
```

### 2. Widget Styling

❌ **Wrong**:

```typescript
<window className="bar">  // className not supported on window
```

❌ **Wrong CSS**:

```css
.volume-widget {
  spacing: 20px; /* Not a valid CSS property */
  min-width: 100%; /* Invalid unit in this context */
}
```

✅ **Correct**:

```typescript
<window css="background: red; min-height: 200px;">
```

### 3. Missing Dependencies

- `AstalWp` (gi://AstalWp) is NOT available by default
- AGS v3 audio services may not be available
- Use external commands like `wpctl` for PipeWire control

### 4. File Extensions

- Use `.tsx` extension for TypeScript JSX files
- Run with: `ags run -g 3 config.tsx`

## Working Patterns

### Basic App Structure

```typescript
import app from "ags/gtk3/app"

function MyWidget() {
    return (
        <window css="background: red; min-height: 200px;">
            <box>
                <label label="Hello World" />
            </box>
        </window>
    )
}

app.start({
    css: "./style.css",
    main() {
        return <MyWidget />
    },
})
```

### State Management

```typescript
import { createState } from "ags"

function Counter() {
    const [count, setCount] = createState(0)

    return (
        <box>
            <label label={count(val => val.toString())} />
            <button onClicked={() => setCount(c => c + 1)}>
                <label label="+" />
            </button>
        </box>
    )
}
```

### CSS Styling Tips

- Use inline `css` prop for simple styling
- External CSS files work but avoid invalid properties
- GTK CSS is NOT web CSS - refer to GTK3/GTK4 docs
- Valid properties: `background`, `color`, `padding`, `margin`, `min-height`, `min-width`
- Invalid properties: `spacing` (use box spacing instead)

### Audio Integration

Since AGS audio services may not work, use shell commands:

```typescript
// Get volume
const getVolume = () => {
  // Use wpctl or pactl commands
};

// Set volume
const setVolume = (value: number) => {
  // Execute shell command to set volume
};
```

## Testing Commands

```bash
# Check AGS version
ags --version

# Run with GTK3
ags run -g 3 config.tsx

# Check running windows in Hyprland
hyprctl clients | grep -i ags
```

## Key Documentation References

- AGS Guide: https://aylur.github.io/ags/guide/
- First Widgets: https://aylur.github.io/ags/guide/first-widgets.html
- Theming: https://aylur.github.io/ags/guide/theming.html
- Quick Start: https://aylur.github.io/ags/guide/quick-start.html

## Common Errors

1. **"No property className on AstalWindow"** - Use `css` prop instead
2. **"Could not resolve astal/gtk3"** - Use `ags/gtk3` imports
3. **"Typelib file for namespace 'AstalWp' not found"** - Use alternative audio solutions
4. **CSS validation errors** - Check GTK CSS documentation for valid properties

## Working Example

The minimal working configuration that displays a red window with text:

```typescript
import app from "ags/gtk3/app"

function TestWindow() {
    return (
        <window css="background: red; min-height: 200px;">
            <box>
                <label label="HELLO WORLD TEST" />
            </box>
        </window>
    )
}

app.start({
    css: "./style.css",
    main() {
        return <TestWindow />
    },
})
```

Run with: `ags run -g 3 config.tsx`

