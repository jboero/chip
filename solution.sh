#/bin/bash -x
git clone https://github.com/chrismatteson/terraform-vault-consul-deployment
cd terraform-vault-consul-deployment/aws/examples/three_clusters_bastion_vpc_peering
terraform init
export TF_VAR_consul_ent_license="01MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JLJCFU3CNPJGXSWJSIV2E6VCJGRNGSMLLJVLU43CMK5GTIT2ELF2E4R2VGRNFIRJVJZVFSM2NK5DGUSLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJUE22SNGRGVIRJVLJUTAMSONVMTGTCUKUYE6VDLORGVOVTKJVBTC2KNNJUGUTTKIF3U2VDINRMXU23JJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U22SBORGUIVLUJVCFEVKNKRGTMTL2IU3E4VCJOVGUIRLZJVVE2MCOIRTXSV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCJO5GFIQJRJRKEC6SWIREXUT3KIF3U62SBO5LWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKIF2E2RCZORGUITSVJVVESNSOKRVTMTSUNN2U6VDLGVLWSSLTJFXFE3DDNUYXAYTNIYYGCVZZOVMDGUTQMJLVK2KPNFEXSTKEJF3UYVCBGJGFIQL2KZCES6KPNJKTKT3KKU2UY2TLGVHVM33JJRBUU53DNU4WWZCXJYYES2TPNFMTEOLVMMZVM42JNF3WSWTNPBUFUM2NNFHW443JMNDUM2TBGJDG4WSTJE3ES3SCPFNFOMLQMRLTA2LGLAYD2LTWMF2WY5B2OYYTURDQKJ3WYZRRIFIXIN2DNU3GE4CFNFLUW43YN5NGUTJYNRJUKVSZMRFVOV2ZKRVWQYRLJZTXASLCLFRHM5DZOE4EOL3IJRBGUYKCIRSUW32CO5VFON3UKZDUGVC2IZCXE3TKIUYUE5Z5HU"
export VAULT_LICENSE="01MV4UU43BK5HGYYTOJZWFQMTMNNEWU33JLJCFU2COK5HGQT2EKV2FSVCCNNNEGMLJLJLUSMCMKRCXSWLNKF2FU3KZPJMXUVJRJV5FCNCZNJVTISLJO5UVSM2WPJSEOOLULJMEUZTBK5IWST3JJJUE22SNGRGVIRJVLJUTAMSONVMTGTCUKUYE6VDLORGVOVTKJVBTC2KNNJUGUTTKIF3U2VDINRMXU23JJRBUU4DCNZHDAWKXPBZVSWCSOBRDENLGMFLVC2KPNFEXCSLJO5UWCWCOPJSFOVTGMRDWY5C2KNETMSLKJF3U2VDLORGVIRLUJVKGQVKNIRTTMTSEIU3E22SFOVGXU2ZQJVKESNKNIRITEV3JJFZUS3SOGBMVQSRQLAZVE4DCK5KWST3JJF4U2RCFGVGFIRLYJRKEKNCWIRAXOT3KIF3U62SBO5LWSSLTJFWVMNDDI5WHSWKYKJYGEMRVMZSEO3DULJJUSNSJNJEXOTLKLF2E2RCJORGUIRSVJVVE2NSOKRVTMTSUNN2U6VDLGVLWSSLTJFXFE3DDNUYXAYTNIYYGCVZZOVMDGUTQMJLVK2KPNFEXSTKEJEZUYVCFPFGFIQLYKZCES6SPNJKTKT3KKU2UY2TLGVHVM33JJRBUU53DNU4WWZCXJYYES2TPNFSG2RRRMJEFC2KMINFG2YSHIZXGG6KJGZSXSSTXLFLU44SZK5SGYSLKN5UWGSCKNRRFO3BRMJJUUOLGKE6T2LTWMF2WY5B2OYYTU4CNJFNDI6CNKF4VOOCONNKTE3DGMZRW6N2NGRXDEWRQKBIU6UC2IFMFOYKZMZ5E24JTINGVEZCXO42TQNCGPFYFU2CHJFAUWVZRGFFUOYTONB4VA5DTGRXU2RKJJZUC6YKWMFTUIUJ5HU"
terraform apply -auto-approve || exit

export VAULT_ADDR=http://localhost:8200

# Disable host checking for ssh keys.
mkdir -p ~/.ssh
cat > ~/.ssh/config <<EOF
Host *
    StrictHostKeyChecking no
EOF
chmod 644 ~/.ssh/config

sleep 10

# Tunnel, init, license all Vaults
for v in Primary DR EU
do
  eval $(terraform output Jump_to_$v)
  vault operator init -format=json -recovery-shares=1 -recovery-threshold=1 -recovery-pgp-keys="keybase:hashicorpchip" > vault.$v.json
  export VAULT_TOKEN=$(jq -r .root_token vault.$v.json)
  vault write sys/license text="$VAULT_LICENSE"
  eval $(terraform output Jump_Close)
done
