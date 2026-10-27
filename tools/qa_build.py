import json, sys

class R:
    def __init__(self):
        self.ev = []
        self.f = 1
    def at(self, f):
        self.f = f
        return self
    def add(self, **kw):
        d = {"frame": self.f}
        d.update(kw)
        self.ev.append(d)
    def wait(self, n):
        self.f += n
    def call(self, target, *args):
        self.add(call=target, args=list(args))
    def scene(self, path):
        self.add(scene=path)
    def expect_scene(self, path):
        self.add(expect_scene=path)
    def shot(self, name):
        self.add(screenshot=name)
    def expect(self, x, y, label, tol=1):
        self.add(expect_tile=[x, y], tolerance=tol, label=label)
    def press(self, action):
        self.add(action=action, pressed=True)
    def release(self, action):
        self.add(action=action, pressed=False)
    def tap(self, action, hold=3, gap=10):
        self.press(action); self.wait(hold); self.release(action); self.wait(gap)
    def hold(self, action, frames):
        self.press(action); self.wait(frames); self.release(action)
    def accept(self, count, gap=10):
        for _ in range(count):
            self.tap("ui_accept", 3, gap)
    def interact(self, gap=10):
        self.tap("interact", 3, gap)
    def tp(self, x, y):
        self.call("Infirmary/Player.set_indexed", "global_position:x", x * 16 + 8)
        self.call("Infirmary/Player.set_indexed", "global_position:y", (y + 1) * 16 - 1)
    def track(self, prefix, count, every):
        for i in range(count):
            self.shot("%s_%03d" % (prefix, i)); self.wait(every)
    def quit(self):
        self.add(quit=True)
    def save(self, path):
        self.ev.sort(key=lambda e: e["frame"])
        with open(path, "w", encoding="utf-8") as fh:
            fh.write("[\n" + ",\n".join("  " + json.dumps(e, ensure_ascii=False) for e in self.ev) + "\n]\n")
