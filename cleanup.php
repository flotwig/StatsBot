<?php
$settings = json_decode(file_get_contents('settings.json'),TRUE);
$channels = explode("\n",file_get_contents('channels.txt'));
chdir($settings['locations']['logs']);
$folders = array_filter(glob('*'),'is_dir');
foreach($folders as $folder){
	if(!in_array($folder,$channels)){
		echo "$folder is no longer being tracked.\n";
		rrmdir($folder);
		unlink('../../htdocs/'.$folder.'.html');	
	}
}

function rrmdir($dir) { 
   if (is_dir($dir)) { 
     $objects = scandir($dir); 
     foreach ($objects as $object) { 
       if ($object != "." && $object != "..") { 
         if (filetype($dir."/".$object) == "dir") rrmdir($dir."/".$object); else unlink($dir."/".$object); 
       } 
     } 
     reset($objects); 
     rmdir($dir); 
   } 
} 
