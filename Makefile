all: check fmt

build::
	nix build '.#cloud-services'

check::
	nix flake check

fmt::
	nix fmt flake.nix pkgs/hunspell-dictionary/default.nix

try::
	$(info NOTE: success IS an empty output)
	echo 'EC2' | nix run '.#demo-hunspell' -- -d cloud-services -l
