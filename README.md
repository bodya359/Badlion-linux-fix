# Badlion-linux-fix
Delete's and modifies badlion "download lunar" tab.
A script that modifies badlion appimage by removing the "download lunar" tab. Tested and running on arch-linux-lts 6.x

FOR EDUCATIONAL/DOCUMENTING PURPOSES ONLY.
I'm isn't associated with mojang/moonsworth, nor mojang AB.

After Lunar bought out Badlion, they added a bar that forces users to download their new "Lunar Client" launcher, most players will choose old Badlion instead of Lunar, On windows you can easily patch the app-update.yml, replacing `https://client-updates.badlion.net/moonsworth` to `https://example.com/` to delete that tab, but on linux all files inside the appimage, and to make it easy, i have done that script. this open-source little file, gives you ability to patch the original appimage and remove this "DOWNLOAD LUNAR!!!!!" bar, and continue playing badlion on linux.

# Patching Badlion

To path badlion, you need to do these steps:
1. download my script by `git clone https://github.com/bodya359/Badlion-linux-fix.git` 
2. download Badlion-appimage [here](https://mikasukie.github.io/BadlionArchive/) or [here](https://github.com/MikaSukie/BadlionArchive)
3. put Badlion-appimage and my script into one directory
4. launch the script from terminal by `sudo chmod +x badlion-lunar-patcher.sh` and `./badlion-lunar-patcher.sh`
5. then type 1 and paste your path to appimage, wait till the process ends, and you're good to go!
6. launch `BadlionClient-patched.AppImage`, wait till badlion loads. login to your Microsoft account, and play minecraft as usual.

# Fixing problems

If you experience problems while using the script.. Then I can't help you with anything ˁ˚ᴥ˚ˀ
Since everything is individual. Try another appimage, or try installing/updating squashfs-tools:
`pacman -Syu squashfs-tools` or `yay -Syu squashfs-tools`
