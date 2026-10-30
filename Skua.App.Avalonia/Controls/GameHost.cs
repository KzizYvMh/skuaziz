using Avalonia.Controls;
using Avalonia.Platform;
using System;

namespace Skua.App.Avalonia.Controls;

#if IS_WINDOWS
using System.Runtime.InteropServices;
using WinForms = System.Windows.Forms;

/// <summary>
/// Hosts the game player's window. The player (another process) is started as a child of <see cref="WindowHandle"/>,
/// a holder created once and moved between native parents, so the game keeps running when Avalonia recreates the
/// native control (e.g. when the window moves between tabs).
/// </summary>
public class GameHost : NativeControlHost
{
    private readonly Holder _holder = new() { Dock = WinForms.DockStyle.Fill, BackColor = System.Drawing.Color.FromArgb(20, 20, 20) };
    private WinForms.Panel? _panel;

    public nint WindowHandle => _holder.Handle;

    protected override IPlatformHandle CreateNativeControlCore(IPlatformHandle parent)
    {
        _panel = new WinForms.Panel { Dock = WinForms.DockStyle.Fill };
        _panel.Controls.Add(_holder);
        return new PlatformHandle(_panel.Handle, "HWND");
    }

    protected override void DestroyNativeControlCore(IPlatformHandle control)
    {
        if (_panel is not null)
        {
            _panel.Controls.Clear();
            _panel.Dispose();
            _panel = null;
        }
    }

    /// <summary>Keeps the player's window filling the holder, from when it is created on.</summary>
    private sealed class Holder : WinForms.Control
    {
        private const int WM_PARENTNOTIFY = 0x0210;
        private const int WM_CREATE = 0x0001;
        private const uint GW_CHILD = 5;
        private const uint SWP_NOZORDER = 0x0004;
        private const uint SWP_NOACTIVATE = 0x0010;

        [DllImport("user32.dll")]
        private static extern nint GetWindow(nint hWnd, uint uCmd);

        [DllImport("user32.dll")]
        private static extern bool SetWindowPos(nint hWnd, nint hWndInsertAfter, int x, int y, int cx, int cy, uint uFlags);

        protected override void WndProc(ref WinForms.Message m)
        {
            base.WndProc(ref m);
            if (m.Msg == WM_PARENTNOTIFY && (m.WParam.ToInt64() & 0xFFFF) == WM_CREATE)
                FitPlayer();
        }

        protected override void OnResize(EventArgs e)
        {
            base.OnResize(e);
            FitPlayer();
        }

        private void FitPlayer()
        {
            nint player = GetWindow(Handle, GW_CHILD);
            if (player != 0)
                SetWindowPos(player, 0, 0, 0, Width, Height, SWP_NOZORDER | SWP_NOACTIVATE);
        }
    }
}
#else
/// <summary>No embedding on this platform yet: the game player opens a window of its own.</summary>
public class GameHost : NativeControlHost
{
    public nint WindowHandle => 0;
}
#endif
