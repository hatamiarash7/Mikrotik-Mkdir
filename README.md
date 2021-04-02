# Mikrotik-Mkdir

A script that creates a `$mkdir` global function. You will be able to create folders on your Mikrotik device by :  

```bash
$mkdir some/new/path.
```

## Installation

Upload `mkdir_function.rsc` to your device and run :

```bash
/import mkdir_function.rsc
```

Or simply run this command in terminal :

```bash
{
    :local result [/tool fetch \
    url="https://raw.githubusercontent.com/hatamiarash7/Mikrotik-Mkdir/main/mkdir_function.rsc" \
    as-value output=user];
    :local script [:parse ($result->"data")]
    $script;
}
```

## Usage

 First, you must have a `:global mkdir;` declaration at the top of your script in order to use `$mkdir`.

On the command line, simply type `$mkdir your/path`, and the entire folder tree will be created. If the path already exists, the function quits.

### Example

For example you can use this function to create a `backups` directory :

```bash
:global mkdir;
$mkdir "backups";
/system backup save name=backups/2021-04-02;
```

## Support

[![Donate with Bitcoin](https://en.cryptobadges.io/badge/micro/3GhT2ABRuHuXGNzP6DH5KvLZRTXCBKkx2y)](https://en.cryptobadges.io/donate/3GhT2ABRuHuXGNzP6DH5KvLZRTXCBKkx2y) [![Donate with Ethereum](https://en.cryptobadges.io/badge/micro/0x4832fd8e2cfade141dc4873cc00cf77de604edde)](https://en.cryptobadges.io/donate/0x4832fd8e2cfade141dc4873cc00cf77de604edde)

[![ko-fi](https://www.ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/D1D1WGU9)

<div><a href="https://payping.ir/@hatamiarash7"><img src="https://cdn.payping.ir/statics/Payping-logo/Trust/blue.svg" height="128" width="128"></a></div>

## Contributing

1. Fork it !
2. Create your feature branch : `git checkout -b my-new-feature`
3. Commit your changes : `git commit -am 'Add some feature'`
4. Push to the branch : `git push origin my-new-feature`
5. Submit a pull request :D

## Issues

Each project may have many problems. Contributing to the better development of this project by reporting them.