# Alternar Resolução

Aplicativo leve para macOS que fica na barra de menus e permite trocar rapidamente a resolução e a taxa de atualização de um monitor externo.

Foi criado para alternar um Samsung Odyssey de 49 polegadas entre o modo ultrawide `5120×1440` e uma área centralizada `2560×1440`, mas lista dinamicamente todos os modos oferecidos pelo monitor conectado.

## Recursos

- Lista todas as resoluções e taxas de atualização disponíveis.
- Indica a resolução atualmente ativa.
- Permite favoritar modos e exibi-los no topo do menu.
- Identifica modos HiDPI e mostra a resolução física correspondente.
- Salva os favoritos entre reinicializações.
- Pode iniciar automaticamente com o macOS.
- Não aparece no Dock.
- Não depende de aplicativos de terceiros.

## Requisitos

- macOS 13 ou mais recente.
- Xcode Command Line Tools para compilar.
- Um monitor externo com modos de resolução compatíveis.

## Instalação

No Terminal, dentro da pasta do projeto:

```sh
chmod +x build.sh install.sh uninstall.sh
./install.sh
```

O aplicativo será instalado em `~/Applications/Alternar Resolucao.app`.

## Uso

1. Clique no ícone de monitor na barra de menus.
2. Escolha uma opção em **Todas as resoluções**.
3. Use **Gerenciar favoritos** para marcar ou desmarcar modos.
4. Ative **Iniciar automaticamente com o macOS** se desejar.

As resoluções favoritas aparecem no topo do menu para acesso rápido.

## Desinstalação

```sh
./uninstall.sh
```

## Como funciona

O projeto usa as APIs nativas `AppKit` e `CoreGraphics`. Os modos são obtidos com `CGDisplayCopyAllDisplayModes`, e a troca é aplicada de forma persistente por meio de `CGDisplayConfigRef`.

## Estrutura

- `ToggleResolution.swift`: aplicativo da barra de menus.
- `Info.plist`: metadados do bundle.
- `build.sh`: compilação e assinatura local.
- `install.sh`: instalação no usuário atual.
- `uninstall.sh`: remoção do aplicativo e da inicialização automática.

## Observações

O aplicativo seleciona o monitor externo ativo com largura mínima de 1920 pixels. Em configurações com vários monitores externos, essa regra pode ser ajustada no método `findOdyssey()`.
