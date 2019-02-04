# Blatant misuse of make to create nice shortcuts for different build profiles. The real build tool is nix.

.PHONY: default
default:
	nix-build

.PHONY: vm
vm:
	nix-build \
		--arg buildInstaller false \
		--arg buildBundle false \
		--arg buildDisk false
	@echo "Run ./result/bin/run-playos-in-vm to start a VM"

.PHONY: validation
validation:
  # TODO: check that we are on correct git branch
	nix-build \
    --arg updateCert ./pki/validation/cert.pem \
		--arg updateUrl https://dist.dividat.com/releases/playos/validation/ \
		--arg deployUrl s3://dist.dividat.ch/releases/playos/validation/ \
		--arg buildDisk false \
		--arg buildInstaller false
	@echo "Run ./result/bin/deploy-playos-update to deploy"
