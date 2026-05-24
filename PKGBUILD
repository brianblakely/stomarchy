# Maintainer: Brian Blakely
pkgname=stomarchy
pkgver=0.1.0
pkgrel=1
pkgdesc="Save and restore your Omarchy config without disrupting its opinionated design"
arch=('any')
url="https://github.com/brianblakely/stomarchy"
license=('MIT')
depends=('bash' 'coreutils' 'grep' 'tar')
optdepends=(
    'curl: for downloading Omarchy releases'
    'wget: alternative to curl for downloading releases'
    'diffutils: for showing config differences'
)
source=("stomarchy")
sha256sums=('SKIP')

package() {
    install -Dm755 "$srcdir/stomarchy" "$pkgdir/usr/bin/stomarchy"
    install -Dm644 "$srcdir/../LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
