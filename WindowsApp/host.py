from __future__ import annotations

import ctypes
import hashlib
import os
import shutil
import sys
import threading
import time
from pathlib import Path

APP_VERSION = "v9.2.2"
MASTER_NAME = "Debate-Coach-web.html"
MASTER_SHA256 = "a8ef90c6ee68ddf24447f0545070bf23e7c35a896a64edc0dc9fd43689447311"
TITLE = "Debate-Coach · 辩论筑基"
DESKTOP_SHORTCUT_SCRIPT = r"""
(function(root){
  function install(w){
    try{
      if(!w.__dcDesktopShortcutsInstalled){
        w.__dcDesktopShortcutsInstalled=true;
        w.addEventListener('keydown',function(e){
          if(e.repeat)return;
          function api(){
            var x=w;
            for(var i=0;i<8;i++){
              try{
                if(x.pywebview&&x.pywebview.api)return x.pywebview.api;
                if(x.parent===x)break;
                x=x.parent;
              }catch(_e){break;}
            }
            return null;
          }
          var a;
          if(e.key==='F11'){
            e.preventDefault();
            e.stopPropagation();
            a=api();
            if(a&&a.toggle_fullscreen)a.toggle_fullscreen();
          }else if(e.key==='Escape'){
            a=api();
            if(a&&a.exit_fullscreen)a.exit_fullscreen();
          }
        },true);
      }
      for(var i=0;i<w.frames.length;i++)install(w.frames[i]);
    }catch(_e){}
  }
  install(root);
})(window);
"""


def message_box(text: str, title: str = TITLE) -> None:
    try:
        ctypes.windll.user32.MessageBoxW(None, text, title, 0x10)
    except Exception:
        pass


def local_appdata() -> Path:
    buf = ctypes.create_unicode_buffer(32768)
    if ctypes.windll.shell32.SHGetFolderPathW(None, 0x001C, None, 0, buf) == 0 and buf.value:
        return Path(buf.value)
    value = os.environ.get("LOCALAPPDATA")
    if value:
        return Path(value)
    return Path.home() / "AppData" / "Local"


def bundle_root() -> Path:
    if getattr(sys, "frozen", False) and hasattr(sys, "_MEIPASS"):
        return Path(sys._MEIPASS)
    return Path(__file__).resolve().parent.parent


def source_master() -> Path:
    candidate = bundle_root() / MASTER_NAME
    if not candidate.is_file():
        raise FileNotFoundError(f"内嵌母版不存在：{candidate}")
    return candidate


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def ensure_master() -> Path:
    src = source_master()
    actual = sha256(src)
    if actual.lower() != MASTER_SHA256:
        raise RuntimeError(f"内嵌母版 SHA-256 不匹配：{actual}")

    target_dir = local_appdata() / "DebateCoach" / "app" / APP_VERSION
    target_dir.mkdir(parents=True, exist_ok=True)
    target = target_dir / "index.html"
    if target.is_file() and sha256(target).lower() == MASTER_SHA256:
        return target

    temp = target.with_suffix(".tmp")
    shutil.copyfile(src, temp)
    if sha256(temp).lower() != MASTER_SHA256:
        temp.unlink(missing_ok=True)
        raise RuntimeError("释放母版后的 SHA-256 校验失败。")
    os.replace(temp, target)
    return target


def webview2_runtime_versions() -> list[str]:
    roots = [
        Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "Microsoft" / "EdgeWebView" / "Application",
        Path(os.environ.get("ProgramFiles", r"C:\Program Files")) / "Microsoft" / "EdgeWebView" / "Application",
    ]
    versions: list[str] = []
    for root in roots:
        if not root.is_dir():
            continue
        for child in root.iterdir():
            if child.is_dir() and child.name[:1].isdigit():
                versions.append(child.name)
    return sorted(set(versions), reverse=True)


def smoke_report() -> str:
    master = source_master()
    return "\n".join(
        [
            f"version={APP_VERSION}",
            f"embedded_master_bytes={master.stat().st_size}",
            f"embedded_master_sha256={sha256(master)}",
            "webview2_runtime=" + (webview2_runtime_versions()[0] if webview2_runtime_versions() else "MISSING"),
        ]
    ) + "\n"


def run_smoke() -> int:
    report = smoke_report()
    exe = Path(sys.executable if getattr(sys, "frozen", False) else __file__).resolve()
    out = exe.with_suffix(".smoke.txt")
    out.write_text(report, encoding="utf-8")
    return 0 if MASTER_SHA256 in report and "webview2_runtime=MISSING" not in report else 1


def executable_sidecar(suffix: str) -> Path:
    exe = Path(sys.executable if getattr(sys, "frozen", False) else __file__).resolve()
    return exe.with_suffix(suffix)


class DesktopApi:
    def __init__(self) -> None:
        self._window = None
        self._fullscreen = False
        self._lock = threading.Lock()
        self._accelerator_handler = None

    def toggle_fullscreen(self) -> bool:
        if self._window is None:
            return False
        with self._lock:
            self._window.toggle_fullscreen()
            self._fullscreen = not self._fullscreen
            return self._fullscreen

    def exit_fullscreen(self) -> bool:
        if self._window is None:
            return False
        with self._lock:
            if not self._fullscreen:
                return False
            self._window.toggle_fullscreen()
            self._fullscreen = False
            return True

    def is_fullscreen(self) -> bool:
        with self._lock:
            return self._fullscreen


def install_native_shortcuts(window, desktop_api: DesktopApi) -> bool:
    native = window.native
    if native is None:
        return False
    if desktop_api._accelerator_handler is not None:
        return True

    control = native.browser.webview
    try:
        from System import Action
        from System.Reflection import BindingFlags

        flags = BindingFlags.Instance | BindingFlags.NonPublic | BindingFlags.Public
        controller = None
        for field in control.GetType().GetFields(flags):
            if str(field.FieldType.FullName) == "Microsoft.Web.WebView2.Core.CoreWebView2Controller":
                controller = field.GetValue(control)
                if controller is not None:
                    break
        if controller is None:
            return False
    except Exception:
        return False

    def on_accelerator(_sender, event) -> None:
        kind = str(event.KeyEventKind)
        if "KeyDown" not in kind:
            return
        try:
            if bool(event.PhysicalKeyStatus.WasKeyDown):
                return
        except Exception:
            pass

        key = int(event.VirtualKey)
        if key == 0x7A:  # F11
            event.Handled = True
            native.BeginInvoke(Action(lambda: desktop_api.toggle_fullscreen()))
        elif key == 0x1B and desktop_api.is_fullscreen():  # Esc
            event.Handled = True
            native.BeginInvoke(Action(lambda: desktop_api.exit_fullscreen()))

    desktop_api._accelerator_handler = on_accelerator
    controller.AcceleratorKeyPressed += on_accelerator

    try:
        window.evaluate_js(DESKTOP_SHORTCUT_SCRIPT)
    except Exception:
        pass

    def register_future_frames() -> None:
        try:
            core = control.CoreWebView2
            if core is not None:
                core.AddScriptToExecuteOnDocumentCreatedAsync(DESKTOP_SHORTCUT_SCRIPT)
        except Exception:
            pass

    native.BeginInvoke(Action(register_future_frames))
    return True


def run_webview(ui_smoke: bool = False) -> int:
    if not webview2_runtime_versions():
        raise RuntimeError("未检测到 Microsoft Edge WebView2 Runtime。请安装或修复 WebView2 Runtime 后再启动。")

    master = ensure_master()
    storage_name = "WebView2-Smoke" if ui_smoke else "WebView2"
    storage = local_appdata() / "DebateCoach" / storage_name
    storage.mkdir(parents=True, exist_ok=True)

    import webview

    webview.settings["ALLOW_DOWNLOADS"] = True
    webview.settings["ALLOW_FILE_URLS"] = True
    webview.settings["OPEN_EXTERNAL_LINKS_IN_BROWSER"] = True
    webview.settings["OPEN_DEVTOOLS_IN_DEBUG"] = False

    desktop_api = DesktopApi()
    window = webview.create_window(
        TITLE,
        url=master.as_uri(),
        js_api=desktop_api,
        width=1100,
        height=680,
        min_size=(760, 520),
        resizable=True,
        hidden=False,
        shadow=True,
        background_color="#0f1117",
        text_select=True,
        zoomable=True,
    )
    desktop_api._window = window

    def install_shortcuts_after_load():
        install_native_shortcuts(window, desktop_api)

    window.events.loaded += install_shortcuts_after_load

    smoke_out = executable_sidecar(".ui-smoke.txt") if ui_smoke else None

    if ui_smoke:
        if smoke_out.exists():
            smoke_out.unlink()

        def loaded():
            try:
                state = window.evaluate_js(
                    "JSON.stringify({ready:document.readyState,title:document.title,"
                    "body:(document.body?document.body.innerText.slice(0,120):'')})"
                )
                smoke_out.write_text(
                    "renderer=" + str(webview.renderer) + "\n" +
                    "url=" + master.as_uri() + "\n" +
                    "state=" + str(state) + "\n",
                    encoding="utf-8",
                )
            except Exception as exc:
                smoke_out.write_text("renderer=" + str(webview.renderer) + "\nerror=" + repr(exc) + "\n", encoding="utf-8")
            finally:
                window.destroy()

        window.events.loaded += loaded

        def watchdog(w, out):
            time.sleep(20)
            if not out.exists():
                out.write_text("renderer=" + str(webview.renderer) + "\nerror=timeout\n", encoding="utf-8")
                try:
                    w.destroy()
                except Exception:
                    pass

        webview.start(
            watchdog,
            args=(window, smoke_out),
            gui="edgechromium",
            debug=False,
            private_mode=False,
            storage_path=str(storage),
        )
        report = smoke_out.read_text(encoding="utf-8") if smoke_out.exists() else "error=no-report"
        ok = (
            "renderer=edgechromium" in report
            and '"ready":"complete"' in report
            and '"title":"Debate-Coach"' in report
            and "工具箱" in report
            and "AI裁判所" in report
        )
        return 0 if ok else 1

    webview.start(
        gui="edgechromium",
        debug=False,
        private_mode=False,
        storage_path=str(storage),
    )
    return 0


def main() -> int:
    if "--smoke" in sys.argv[1:]:
        return run_smoke()

    try:
        return run_webview(ui_smoke="--ui-smoke" in sys.argv[1:])
    except Exception as exc:
        if "--ui-smoke" in sys.argv[1:]:
            executable_sidecar(".ui-smoke.txt").write_text("error=" + repr(exc) + "\n", encoding="utf-8")
        else:
            message_box("Debate-Coach 无法启动。\n\n" + str(exc), f"Debate-Coach {APP_VERSION}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
