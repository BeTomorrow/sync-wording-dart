# Sync Wording

This tool allow you to manage app's wording with simple Google Sheet file. Just create a sheet with columns for keys and wording. This tool will generate wording files. Your product owner will be able to edit himself application's wording

## Quick Start

You can find a sample sheet [here](https://docs.google.com/spreadsheets/d/18Zf_XSU80j_I_VOp9Z4ShdOeUydR6Odyty-ExGBZaz4/edit?usp=sharing) but it's just a simple sheet with one column for keys and columns for languages like this

| Keys                 | English   | French |
| -------------------- | --------- | ------ |
| user.firstname_title | Firstname | Prénom |
| user.lastname_title  | Lastname  | Nom    |

## Integration to your project

- Install sync-wording as dev dependencies `flutter pub add dev:@betomorrow/sync-wording-dart`
- Create wording config file named `wording_config.yaml` at project root location.

```yaml
credentials:
  client_id: "your.google.client.id"
  client_secret: "your.google.client.secret"

sheetId: "18Zf_XSU80j_I_VOp9Z4ShdOeUydR6Odyty-ExGBZaz4"
sheetNames: ["Commons", "MyApp"]
output_dir: "outputs"
languages:
  en:
    column: 3
  fr:
    column: 4
    # column : 1='A', 2='B', ...
```

- Then run `dart run sync-wording-dart`

It will ask you to grant access on Google Sheet

```bash
> Task :app:downloadWording
Please open the following address in your browser:
  https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&scope=...

```

- Open url in your browser
- Grant access

[Authorization Sample]

It will update wording files : `${output_dir}/intl_en.arb` and `${output_dir}/intl_fr.arb`

If `gen_l10n:auto_call` is `true`, the program will automatically execute `flutter gen_l10n`, or `fvm flutter gen_l10n` if `gen_l10n:with_fvm` is `true`, to generate localization classes (`l10n.yaml` file is required)

## Placeholders

You can specify placeholders in your translations, with their type and format:

```
Hello {name} => Create a default 'Object' placeholder
Hello {name|String} => Create a 'String' placeholder
It is {now|DateTime|hh:mm:ss)} => Create a 'DataTime' placeholder that will be formatted like '14:09:15'
```

(separator is `|`)

This also works with plurals for example:

```
{days, plural, zero{today} one{tomorrow} other{in {days|int} days}}
```

## Wording validation (Will come soon)

## Options

This tools support 2 options

- **`--config`** : Configuration file path
- **`--help`** : Display help info


[//]: # (- **`--upgrade`** : Export sheet in local xlsx file that you can commit for later edit. It prevent risks to have unwanted wording changes when you fix bugs. And then update wording)

[//]: # (- **`--update`** : Update wording files from local xlsx file)

[//]: # (- **`--invalid`** : &#40;error|warning&#41; exist with error when invalid translations found or just warn)

## Complete Configuration

```yaml
credentials:
  client_id: "your.google.client.id"
  client_secret: "your.google.client.secret"
  credentials_file: ".google_credentials.json"

sheetId: "18Zf_XSU80j_I_VOp9Z4ShdOeUydR6Odyty-ExGBZaz4"
sheetNames: ["Commons", "MyApp"]
output_dir: "outputs"
languages:
  en:
    column: 3
  fr:
    column: 4
    # column : 1='A', 2='B', ...

gen_l10n:
  auto_call: true
  with_fvm: true
```
