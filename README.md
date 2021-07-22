This program is created to check plot files for crossing nonces:
1) The program can automatically read a miner config (foxy-miner, scavanger, signum-miner, btdex). For foxy-miner there is no difference where the program is located, for the rest of the programs the miner must be launched from the directory it located;
2) There is an option to manually select a folder with plot files to add all plot file names to the list;
3) There is an option to save and load the document with a list of previously saved plot files, for checking crossing nonces between multiple machines;
4) Shows detailed information about plot files with crossing nonces: path, plot file's name, starting cross nonce, ending cross nonce, crossing length nonces, crossing volume in TiB;
5) Shows the actual volume in TiB and the volume seen by the network (with a difference in the volume of crossing nonces)
