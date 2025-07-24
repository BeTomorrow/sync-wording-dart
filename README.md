# Sync Wording

This tool allows you to manage your app's wording with a simple Google Sheets file. Just create a sheet with columns for keys and wording. This tool will generate wording files. Your product owner will be able to edit the application's wording themselves.

## Quick Start

You can find a sample sheet [here](https://docs.google.com/spreadsheets/d/18Zf_XSU80j_I_VOp9Z4ShdOeUydR6Odyty-ExGBZaz4/edit?usp=sharing), but it's just a simple sheet with one column for keys and columns for languages like this:

| Keys           | English   | French |
| -------------- | --------- | ------ |
| user.firstname | Firstname | Prénom |
| user.lastname  | Lastname  | Nom    |

## Installation

- Install sync-wording as a dev dependency: `flutter pub add dev:sync_wording`
- Create a wording config file named `wording_config.yaml` at the project root location.

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

It will ask you to grant access to Google Sheets:

```bash
> Task :app:downloadWording
Please open the following address in your browser:
  https://accounts.google.com/o/oauth2/v2/auth?access_type=offline&scope=...

```

- Open the URL in your browser
- Grant access

[Authorization Sample]

It will update the wording files: `${output_dir}/intl_en.arb` and `${output_dir}/intl_fr.arb`

## Placeholders

You can specify placeholders in your translations, with their type and format:

```
Hello {name} => Creates a default placeholder
Hello {name|String} => Creates a 'String' placeholder
It is {now|DateTime|hh:mm:ss} => Creates a 'DateTime' placeholder that will be formatted like '14:09:15'
```

(separator is `|`)

This also works with plurals, for example:

```
{days, plural, zero{today} one{tomorrow} other{in {days|int} days}}
```

## Configuration options

### Sheet names

If your Google Sheets document contains many sheets, all sheets will be considered as valid input sheets.
If you only want to use a subset of these sheets, you can specify the sheet names needed as input:

```yaml
sheetNames: ["Commons", "MyApp"]
```

### Key column

By default, the column containing the translation keys is the first column (column 'A'), but you can specify another key column if your Google Sheets document has a different format.

```yaml
key_column: 2 # default : 1
```

### Starting row for values

By default, the first row is considered as a header, and valid keys and translations start at the second row.
If your Google Sheets document is not in this format, you can specify the row from which translations will be taken into account:

```yaml
sheet_start_index: 3 # default : 2
```

### Wording validation

In your Google Sheets, you can add a column to indicate that it's a valid translation:

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

If no `validation` is specified, everything is considered as valid.

### Fallback translations

When a translation is missing in one language, you can configure the tool to automatically use the translation from a default language as fallback. This is useful to ensure all languages have complete translations.

```yaml
fallback:
  enabled: true
  default_language: "en"
  # When a translation is missing in a language, use the translation from default_language
```

If `fallback` is not specified, no fallback behavior is applied and missing translations will be reported as warnings.

## Localization classes generation

Executing this program will generate the `.arb` localization files.
But it can go further:
If your Flutter project is configured to use localizations, with a proper `l10n.yaml` file, this program can automatically generate the localization Dart classes by running the `flutter gen-l10n` command itself, or even `fvm flutter gen-l10n` if you chose fvm as the Flutter version manager for your project.
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

This tool supports 2 options:

- **`--config`** : Configuration file path (Optional: defaults to `./wording_config.yaml`)
- **`--help`** : Display help info

## Complete Configuration

Complete example of a `wording_config.yaml` file:

```yaml
sheetId: "your.sheet.id"
output_dir: "lib/localizations"
sheetNames: ["Commons", "MyApp"] # (Optional)
sheet_start_index: 2 # (Optional) defaults to 2

# column values : 1='A', 2='B', ...
key_column: 1 # (Optional) defaults to 1
languages:
  en:
    column: 3
  fr:
    column: 4
validation: # (Optional)
  column: 5
  expected: "OK"

fallback: # (Optional)
  enabled: true
  default_language: "en"

credentials: # (Optional)
  client_id: "your-client-id"
  client_secret: "your-client-secret"
  credentials_file: ".google_access_token.json" # (Optional: defaults to .google_access_token.json)

gen_l10n: # (Optional)
  auto_call: true
  with_fvm: true # (Optional)
```
