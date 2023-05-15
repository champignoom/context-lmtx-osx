## Installation

Add `tex/texmf-linux-64/bin` to `$PATH`, then run
```
mtxrun --generate && context --make
```

To install fonts:
```
OSFONTDIR=/System/Library/Fonts:/Library/Fonts mtxrun --scripts font --reload
```

To install modules:
```
(cd tex && mtxrun --script install-modules --install --all)
```
