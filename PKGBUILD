# Maintainer: Brian Blakely
pkgname=stomarchy
pkgver=0.2.0
pkgrel=1
pkgdesc="Safely preserve append-only Omarchy Quattro customizations"
arch=('any')
url="https://github.com/brianblakely/stomarchy"
license=('MIT')
depends=('bash' 'coreutils' 'diffutils' 'findutils' 'foot' 'gawk' 'grep' 'lua' 'sed' 'util-linux')
source=(
  'stomarchy'
  "stomarchy.bash::file://$startdir/completions/stomarchy.bash"
  "stomarchy.1::file://$startdir/man/stomarchy.1"
  'LICENSE'
)
sha256sums=(
  'd3f00db06f27d8ba31c9467d8b07c3c4e2a0eb92776f3aed3ae6a1fe58c93771'
  '2ac2a08b34f5e45e400853d13ffd1067c223357733562f48ba66eeb2ff88a2ff'
  '22939b4e43d131d363cb605e5e643c3cc37ee244087340b222a140b4302df908'
  'e84a5891e4e9c11d104a39221093f152f4dbe20b4f99802fea1c87bc52d5ac01'
)

package() {
  install -Dm755 "$srcdir/stomarchy" "$pkgdir/usr/bin/stomarchy"
  install -Dm644 "$srcdir/stomarchy.bash" "$pkgdir/usr/share/bash-completion/completions/stomarchy"
  install -Dm644 "$srcdir/stomarchy.1" "$pkgdir/usr/share/man/man1/stomarchy.1"
  install -Dm644 "$srcdir/LICENSE" "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
