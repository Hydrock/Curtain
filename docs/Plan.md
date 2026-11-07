# Curtain

Native macOS menu bar app, Swift + AppKit, macOS 14+, no dependencies.
Two fabric panels over a selected application's window. Drag any fabric point;
release with inertia. Double click toggles the panel. Top anchors slide along a rail.
Window title bar remains usable. Accessibility permission is requested only when
selecting external windows. Demo works without permission. No screen recording.

Implementation:
1. Test a standalone cloth simulation for opening, deformation, settling and resize.
2. Implement damped spring mesh and shaded fabric rendering.
3. Implement transparent panels, hit testing, window tracking and menu controls.
4. Add a welcome/demo window, build script, app bundle and Russian instructions.
5. Compile, run physics tests, launch and inspect UI; copy project to Desktop/Curtain.

Limitations: external curtains are shown when their owner is frontmost to avoid
covering unrelated apps. Accessibility implementations differ between apps.
