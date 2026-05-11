#!/usr/bin/env bash
set -e

# Kodi Docker Entrypoint
# Modes:
#   headless  — Xtigervnc as X server, optional VNC/noVNC access (default)
#   gui       — X11 forwarding from host, fullscreen
#   windowed  — X11 forwarding from host, window with configurable resolution

readonly KODI_MODE="${KODI_MODE:-headless}"
readonly KODI_RESOLUTION="${KODI_RESOLUTION:-1280x720}"
readonly ENABLE_VNC="${ENABLE_VNC:-true}"
readonly ENABLE_NOVNC="${ENABLE_NOVNC:-true}"

log() { echo "---> [entrypoint] $1"; }

# Patch guisettings.xml to enable services and configure display
patch_guisettings() {
    local gs="/root/.kodi/userdata/guisettings.xml"
    [ -f "$gs" ] || return 0

    log "Patching guisettings.xml: enabling webserver, JSON-RPC, EventServer"
    sed -i \
        -e 's|<setting id="services.webserver"[^>]*>[^<]*</setting>|<setting id="services.webserver">true</setting>|' \
        -e 's|<setting id="services.webserverport"[^>]*>[^<]*</setting>|<setting id="services.webserverport">8080</setting>|' \
        -e 's|<setting id="services.webserverauthentication"[^>]*>[^<]*</setting>|<setting id="services.webserverauthentication">false</setting>|' \
        -e 's|<setting id="services.esallinterfaces"[^>]*>[^<]*</setting>|<setting id="services.esallinterfaces">true</setting>|' \
        -e 's|<setting id="services.esenabled"[^>]*>[^<]*</setting>|<setting id="services.esenabled">true</setting>|' \
        -e 's|<setting id="screensaver.mode"[^>]*>[^<]*</setting>|<setting id="screensaver.mode"></setting>|' \
        "$gs"

    # Configure windowed mode if requested
    if [ "$KODI_MODE" = "windowed" ] || [ "$KODI_MODE" = "headless" ]; then
        local width="${KODI_RESOLUTION%x*}"
        local height="${KODI_RESOLUTION#*x}"
        log "Setting display: ${width}x${height} (windowed)"
        sed -i \
            -e 's|<setting id="videoscreen.screenmode"[^>]*>[^<]*</setting>|<setting id="videoscreen.screenmode">WINDOW</setting>|' \
            "$gs"
    fi
}

# Create advancedsettings.xml for network/cache tuning
ensure_advancedsettings() {
    local as="/root/.kodi/userdata/advancedsettings.xml"
    [ -f "$as" ] && return 0

    log "Creating advancedsettings.xml"
    cat > "$as" << 'EOF'
<advancedsettings version="1.0">
    <cache>
        <memorysize>52428800</memorysize>
        <readfactor>4</readfactor>
    </cache>
    <loglevel>1</loglevel>
    <debug>
        <extralogging>true</extralogging>
    </debug>
</advancedsettings>
EOF
}

# First-run: start Kodi briefly to generate guisettings.xml
first_run_setup() {
    local gs="/root/.kodi/userdata/guisettings.xml"
    [ -f "$gs" ] && return 0

    log "First run: generating guisettings.xml..."
    Xtigervnc -SecurityTypes None -geometry "${KODI_RESOLUTION}" -depth 24 -rfbport 5999 :99 &>/dev/null &
    local xvnc_pid=$!
    sleep 2

    DISPLAY=:99 /usr/bin/kodi --standalone --windowing=x11 &>/dev/null &
    local kodi_pid=$!

    local i=0
    while [ $i -lt 15 ] && [ ! -f "$gs" ]; do
        sleep 1
        i=$((i + 1))
    done
    sleep 2

    DISPLAY=:99 kodi-send --action="Quit" &>/dev/null || true
    sleep 3
    kill $kodi_pid 2>/dev/null || true
    wait $kodi_pid 2>/dev/null || true
    kill $xvnc_pid 2>/dev/null; wait $xvnc_pid 2>/dev/null || true
    rm -f /tmp/.X99-lock /tmp/.X11-unix/X99

    [ -f "$gs" ] && log "guisettings.xml generated successfully" || log "WARNING: guisettings.xml not generated"
}

# Start in headless mode (Xtigervnc + supervisord)
start_headless() {
    log "Starting in HEADLESS mode (resolution: ${KODI_RESOLUTION}, VNC: ${ENABLE_VNC}, noVNC: ${ENABLE_NOVNC})"

    local conf="/etc/supervisor/conf.d/kodi.conf"
    if [ "$ENABLE_VNC" != "true" ]; then
        # Disable VNC but keep X server (rfbport 0 = no VNC listener)
        sed -i 's|command=/usr/bin/Xtigervnc.*|command=/usr/bin/Xtigervnc -SecurityTypes None -geometry '"${KODI_RESOLUTION}"' -depth 24 -rfbport 0 :99|' "$conf"
    fi
    if [ "$ENABLE_NOVNC" != "true" ]; then
        sed -i '/\[program:novnc\]/a autostart=false' "$conf"
    fi

    exec /usr/bin/supervisord -c "$conf"
}

# Start in GUI/windowed mode (X11 forwarding from host)
start_gui() {
    local mode_label="GUI (fullscreen)"
    local kodi_args="--windowing=x11 --standalone"

    if [ "$KODI_MODE" = "windowed" ]; then
        mode_label="WINDOWED (${KODI_RESOLUTION})"
        kodi_args="--windowing=x11"
    fi

    log "Starting in ${mode_label} mode (DISPLAY=${DISPLAY})"
    trap 'kodi-send --action="Quit" 2>/dev/null; sleep 2' EXIT
    exec /usr/bin/kodi $kodi_args
}

# Apply config overlay from /config if mounted
apply_config_overlay() {
    local config_dir="/config"
    [ -d "$config_dir" ] || return 0

    local userdata="/root/.kodi/userdata"
    log "Applying config overlay from /config"

    # Copy all files from /config to userdata, preserving structure
    cp -a "$config_dir"/. "$userdata"/ 2>/dev/null || true
    log "Config overlay applied"
}

# Main
ensure_advancedsettings
first_run_setup
apply_config_overlay
patch_guisettings

case "$KODI_MODE" in
    headless)         start_headless ;;
    gui|windowed)     start_gui ;;
    *)                log "ERROR: Unknown KODI_MODE=$KODI_MODE (use: headless, gui, windowed)"; exit 1 ;;
esac
