import app from "ags/gtk3/app"
const { GLib } = imports.gi

function VolumeWidget() {
    let currentVolume = 0.5
    
    // Get initial volume on startup
    try {
        const [success, stdout] = GLib.spawn_command_line_sync("wpctl get-volume @DEFAULT_AUDIO_SINK@")
        if (success && stdout) {
            const output = new TextDecoder().decode(stdout)
            const match = output.match(/Volume: ([\d.]+)/)
            if (match) {
                currentVolume = parseFloat(match[1])
            }
        }
    } catch (error) {
        console.error("Failed to get initial volume:", error)
    }
    
    return (
        <box css="background: red; padding: 50px; border-radius: 8px; min-width: 600px; min-height: 200px;">
            <icon 
                icon="audio-volume-medium"
                css="color: white; font-size: 48px;"
            />
            <slider
                css="min-width: 400px; min-height: 50px;"
                hexpand
                drawValue={false}
                min={0}
                max={1}
                step={0.01}
                value={currentVolume}
                onDragged={({ value }) => {
                    console.log(`Volume: ${Math.floor(value * 100)}%`)
                    // Set system volume using wpctl with decimal format
                    const command = `wpctl set-volume @DEFAULT_AUDIO_SINK@ ${value}`
                    try {
                        GLib.spawn_command_line_async(command)
                    } catch (error) {
                        console.error("Failed to set volume:", error)
                    }
                }}
            />
            <label
                css="color: white; font-weight: bold; font-size: 24px; min-width: 100px;"
                label={`${Math.floor(currentVolume * 100)}%`}
            />
        </box>
    )
}

function Bar() {
    return (
        <window
            css="background: rgba(0,255,0,0.5);"
        >
            <box css="padding: 100px;" halign="center" valign="center">
                <VolumeWidget />
            </box>
        </window>
    )
}

app.start({
    css: "./style.css",
    main() {
        return <Bar />
    },
})