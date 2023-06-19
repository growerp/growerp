# HTML Website

The html website from the standard Moqui is used, however with major changes to make it multicompany. All changes are in the growerp branch while the master branch is a clone of the Moqui repository.

# POP REST Store - eCommerce REST API and Web App

Component cloned from the [original repository](https://github.com/moqui/PopRestStore) with major changes as listed below 

A big thanks for the original developers!

Major changes:

1. multi organizational companies
2. support different currencies ([needs mantle-usl change](https://github.com/moqui/mantle-usl/pull/188))
3. various fault fixes
4. customers have related company
5. orders on company partyId, customer person on orderparty entity
6. uses a Growerp API call
7. removed store from the url added store dependent subdomain name using the productStoreId.
8. Can change the website colors from the growerp admin app

[![license](https://camo.githubusercontent.com/b8b67a74b25cc3f9256a99543445930a65ca6d03ad3037f193f24263f15a152b/687474703a2f2f696d672e736869656c64732e696f2f62616467652f6c6963656e73652d434330253230312e30253230556e6976657273616c2d626c75652e737667)](https://github.com/moqui/PopRestStore/blob/master/LICENSE.md) [![release](https://camo.githubusercontent.com/0e74b5aac60e4557498712ae9edca6e79a9f42aadaffef68d93232a580899d71/687474703a2f2f696d672e736869656c64732e696f2f6769746875622f72656c656173652f6d6f7175692f506f705265737453746f72652e737667)](https://github.com/moqui/PopRestStore/releases) [![commits since release](https://camo.githubusercontent.com/cb9d197181e2e59d921f48d5b5b0a9f903b6410d39700ec16dc5a63f0f8826d1/687474703a2f2f696d672e736869656c64732e696f2f6769746875622f636f6d6d6974732d73696e63652f6d6f7175692f506f705265737453746f72652f76312e302e302e737667)](https://github.com/moqui/PopRestStore/commits/master)