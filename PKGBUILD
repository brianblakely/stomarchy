# Maintainer: Brian Blakely
pkgname=stomarchy
pkgver=0.1.0
pkgrel=1
pkgdesc="Save and restore your Omarchy config without disrupting its opinionated design"
arch=('any')
url="https://github.com/brianblakely/stomarchy"
license=('MIT')
depends=('bash' 'coreutils' 'diffutils' 'findutils' 'gawk' 'grep' 'sed')
source=("stomarchy")
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/stomarchy" "$pkgdir/usr/bin/stomarchy"
    install -Dm644 "$srcdir/../LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
