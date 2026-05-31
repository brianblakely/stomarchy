# Maintainer: Brian Blakely
pkgname=stomarchy
pkgver=0.1.0
pkgrel=1
pkgdesc="Save and restore your Omarchy config without disrupting its opinionated design"
arch=('any')
url="https://github.com/brianblakely/stomarchy"
license=('MIT')
depends=('bash' 'coreutils' 'diffutils' 'findutils' 'gawk' 'grep' 'sed')
source=(
    "stomarchy"
    "stomarchy.bash::completions/stomarchy.bash"
    "stomarchy.1::man/stomarchy.1"
)
sha256sums=('SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 "$srcdir/stomarchy" "$pkgdir/usr/bin/stomarchy"
    install -Dm644 "$srcdir/stomarchy.bash" "$pkgdir/usr/share/bash-completion/completions/stomarchy"
    install -Dm644 "$srcdir/stomarchy.1" "$pkgdir/usr/share/man/man1/stomarchy.1"
    install -Dm644 "$srcdir/../LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
