<?php
set_time_limit(0); // so your bot doesn't die after 30 seconds
date_default_timezone_set(date_default_timezone_get()); // because PHP can be a bitch sometimes
final class StatsBot {
	private $settings;
	private $socket;
	private $nick;
	private $channels;
	function __construct(){
		$this->settings=file_get_contents('settings.json');
		$this->settings=json_decode($this->settings,TRUE);
		$this->channels=file_get_contents('channels.txt');
		$this->channels=explode("\n",$this->channels);
		$this->nick=$this->settings['identity']['nick'];
		$this->connect();
		while(!feof($this->socket)){
			$this->mainLoop();
		}
	}
	function __destruct(){
		// TODO: Send quit, close file handlers
	}
	function connect(){
		$uri=$this->settings['server'];
		if($this->settings['ssl'])$uri='ssl://'.$uri;
		$this->socket=fsockopen($uri,$this->settings['port'],$errno,$errstr,20);
		stream_set_blocking($this->socket,1); // we fix the dreaded 100% CPU issue
		$this->send('USER '.$this->settings['identity']['ident'].' 8 * :'.$this->settings['identity']['realname']);
		$this->send('NICK '.$this->nick);
	}
	function mainLoop(){
		// data extraction
		$buffer=fgets($this->socket);
		$buffer=substr($buffer,0,strlen($buffer)-2); //remove \r\n
		var_dump($buffer);
		if(empty($buffer))return;
		$bufferParts=explode(' ',$buffer);
		$nick=explode('!',$bufferParts[0]);
		$nick=substr($nick[0],1);
		$channel=@$bufferParts[2];
		$inConvo=($channel==$this->nick);
		if ($inConvo)$channel=$nick;
		$arguments=$bufferParts;
		$i=0;
		while($i++<3)array_shift($arguments);
		if($bufferParts[1]==='002'){ // connection established keyword
			sleep(1); // secret sauce
			$this->send('MODE '.$this->nick.' +B'); // we are a bot
			if($this->settings['nickserv']['pass']!==''){
				$this->msg('NickServ','IDENTIFY'.
								$this->settings['nickserv']['nick'].
								$this->settings['nickserv']['pass']);
			}	
			foreach($this->channels as $channel){
				$this->send('JOIN '.$channel);
			}
		}elseif($bufferParts[0]==='PING'){
			$this->send('PONG ' . str_replace(array("\n","\r"),'',end(explode(' ',$buffer,2))));
		}elseif(in_array(':'.strtolower($this->settings['command']),$bufferParts)){
			$this->msg($nick,'Stats for this channel can be found at '.
												$this->settings['locations']['url'].
												$channel.'.html',
												'NOTICE');
		}elseif(strtolower($bufferParts[1])==='invite'){
			$this->send('JOIN '.$arguments[0]);
			$this->channels[]=substr($arguments[0],1);
			$this->saveChannels();
		}elseif(strtolower($bufferParts[1])==='kick'&&strtolower($bufferParts[3])===strtolower($this->nick)){
			$this->channels=array_diff($this->channels,array($bufferParts[2]));
			$this->saveChannels();
		}
	}
	function saveChannels(){
		return file_put_contents('channels.txt',implode("\n",$this->channels));
	}
	function send($line){
		echo $line."\n";
		return fwrite($this->socket,$line."\n\r");
	}
	function msg($to,$message,$type='PRIVMSG'){
		return $this->send($type.' '.$to.' :'.$message);
	}
}
$bot=new StatsBot;