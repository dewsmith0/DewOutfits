# DewOutfits
**DewOutfits** (by Dewsmith) is an outfit loader for Figura. It loads textures from the data folder and sends them in pings, allowing you to save on avatar space. 
## How do I download this??
Click `<> Code`, `Download ZIP` in the top right above the commit counter. 
## How to use
It's not that hard, but requires some setup. An example model is in this repo, and the script is preconfigured to try to set those modelparts' textures.  
For a simple setup with outfit support for arms, legs, and the body, just copy the parts with "Outfit" in the name to your model, making sure you keep them in the correct groups. Or just change the model references in the config, at the top of the script.  
Then, require the script somewhere, and add `DewOutfits.addAction(page)`, where `page` is the action wheel page you want to put it in.  
Just making this clear: **Outfits are stored in your Figura data folder, in `DewOutfits/` by default. This folder will automatically be created by default.**  

There are some options you can change, besides `parts`:
- `chunkSize` (default `400`) is the most important one, it determines how many bytes of Base64 are sent per ping (twice a second). If you have supporter, you might be able to double this, but don't count on it as backend lag usually lowers the effective limit. Don't set this too high or pings might fail. 
- `repingTime` (default `800`) controls how often (in ticks) the outfit is pinged again automatically, so that people don't miss out on it because they weren't loaded. Outfits are only repinged when you're not already pinging one.
- `outfitDir` (default `DewOutfits/`) is the subfolder of `data` where the script loads outfits from. If it doesn't exist, it will automatically be created.

## Important notes
- Make sure the outfit model parts you select are set to hidden in Blockbench, and have a dummy texture (can be empty) with the same size and UVs as your outfits.
- This script was written with no reference to any other outfit scripts, other than for the actual `applyOutfit` function. Isn't that cool? I learned so much from this.

## Licensing
[**Creative Commons Attribution-NonCommercial-ShareAlike 4.0**](https://creativecommons.org/licenses/by-nc-sa/4.0/)  
<ins>Exception: FiguraMC Verified Creators may use this script in paid avatars or commissions sold through the official FiguraMC Discord.</ins> *But please do tell me if you do use it like that.*  
The functions `getNextScrollOption()` and `getScrollTitle()` were written by Dyrris__ (dyrris_agni), used with permission. 
