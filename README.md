# Sync Wording

This tool allow you to manage app's wording with simple Google Sheet file. Just create a sheet with columns for keys and wording. This tool will generate wording files. Your product owner will be able to edit himself application's wording

## Quick Start

You can find a sample sheet [here](https://docs.google.com/spreadsheets/d/18Zf_XSU80j_I_VOp9Z4ShdOeUydR6Odyty-ExGBZaz4/edit?usp=sharing) but it's just a simple sheet with one column for keys and columns for languages like this

| Keys                 | English   | French |
| -------------------- | --------- | ------ |
| user.firstname_title | Firstname | Prénom |
| user.lastname_title  | Lastname  | Nom    |

## Installation

- Install sync-wording as dev dependencies `flutter pub add dev:sync_wording`
- Create wording config file named `wording_config.yaml` at project root location.

```yaml
sheetId: "your.sheet.id"
output_dir: "lib/localizations"
languages:
  en:
    column: 3
  fr:
    column: 4
    # column : 1='A', 2='B', ...
```

- Then run `flutter pub run sync_wording`

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

## Configuration options

### Sheet names

If your GoogleSheet document contains many sheets, all the sheets will be considered as valid input sheet.
If you only want to use a subset of these sheets, you can specify the sheet-names needed as input

```yaml
sheetNames: ["Commons", "MyApp"]
```

### Key column

By default the column containing the translation keys is the first column (column 'A'), but you can specify another key column if your GoogleSheet document has another format.

```yaml
key_column: 2 # default : 1
```

### Starting row for values

By default, the first row is considered as a header, valid keys and translations start at the second row.
If you GoogleSheet document is not in this format, you can specify the row from which translations will be taken in account:

```yaml
sheet_start_index: 3 # default : 2
```

### Wording validation

In your google sheet, you can add column indicate that it's a valid translation

| Keys                 | English   | French | Validation |
| -------------------- | --------- | ------ | ---------- |
| user.firstname_title | Firstname | Prénom | OK         |
| user.lastname_title  | Lastname  | Nom    | NOT OK     |

Then add this to your configuration file:

```yaml
validation:
  column: 5
  expected: "OK"
```

If no `validation` specified, everything is considered as valid.

## Localization classes generation

Executing this program will generate the `.arb` localization files.
But it can go further:
If your Flutter project is configured to use localizations, with a proper `l10n.yaml` file, this program can automatically generate the localization dart classes by running by itself the `flutter gen-l10n` command, or even `fvm flutter gen-l10n` if you chose fvm as flutter version manager for your project.
You can simply add this to your `wording_config.yaml` file:

```yaml
gen_l10n:
  auto_call: true
  with_fvm: true
```

## Use your own Google Application

By default, the tool uses a pre-configured Google Application. If you want to use your own Google Application:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google Sheets API for your project
4. Go to "Credentials" and create a new OAuth 2.0 Client ID
5. Configure the OAuth consent screen if not already done
6. Download the client credentials or copy the client ID and client secret

Then add these credentials to your `wording_config.yaml`:

```yaml
credentials:
  client_id: "your-client-id"
  client_secret: "your-client-secret"
  credentials_file: ".google_access_token.json" # Optional: defaults to .google_access_token.json
```

The `credentials_file` is where the OAuth tokens will be stored. Make sure to add this file to your `.gitignore` to keep your tokens secure.

## Options

This tools support 2 options

- **`--config`** : Configuration file path (Optional : defaults to `./wording_config.dart`)
- **`--help`** : Display help info

## Complete Configuration

Complete example of a `wording_config.yaml` file:

```yaml
sheetId: "your.sheet.id"
output_dir: "lib/localizations"
sheetNames: ["Commons", "MyApp"] # (Optional)
sheet_start_index: 2 # (Optional) defaults 2

# column values : 1='A', 2='B', ...
key_column: 1 # (Optional) defaults 1
languages:
  en:
    column: 3
  fr:
    column: 4
validation: # (Optional)
  column: 5
  expected: "OK"

gen_l10n: # (Optional)
  auto_call: true
  with_fvm: true # (Optional)
```
