<?php
set_time_limit(0); // so your bot doesn't die after 30 seconds
date_default_timezone_set(date_default_timezone_get()); // because PHP can be a bitch sometimes
echo 'Running.'."\n";
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
		if($this->socket)unset($this);
		while($this->socket){
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
		if(empty($buffer))return;
		$bufferParts=explode(' ',$buffer);
		$nick=explode('!',$bufferParts[0]);
		$nick=substr($nick[0],1);
		$channel=@$bufferParts[2];
		if($channel&&substr($channel,0,1)===':'){
			$channel=substr($channel,1);
		}
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
			$pingReply=explode(' ',$buffer,2);
			$this->send('PONG '.str_replace("\n\r",'',end($pingReply)));
		}elseif(in_array(':'.$this->settings['command'],$bufferParts)){
			$this->msg($nick,'Stats for this channel can be found at '.
												$this->settings['locations']['url'].
												$this->fixDir($channel).'.html',
												'NOTICE');
		}elseif(strtolower($bufferParts[1])==='invite'){
			$this->send('JOIN '.$arguments[0]);
			$this->channels[]=substr($arguments[0],1);
			$this->saveChannels();
		}elseif(strtolower($bufferParts[1])==='kick'&&strtolower($bufferParts[3])===strtolower($this->nick)){
			$this->channels=array_diff($this->channels,array($bufferParts[2]));
			$this->saveChannels();
		}elseif(strtolower($bufferParts[1])==='privmsg'&&
				$bufferParts[2]===$this->nick&&
				in_array(':help',$bufferParts)){
			$this->msg($nick,'For help with this bot, visit https://goo.gl/tUAEvh','NOTICE');
		}
		$this->logLine($buffer,$bufferParts,$nick,$channel);
	}
	function saveChannels(){
		file_put_contents('channels.txt',implode("\n",$this->channels));
		$pisg='';
		foreach($this->channels as $channel){
			$pisg.=	'<channel="'.$channel.'">'."\n".
					'	OutputFile="'.$this->settings['locations']['stats'].$this->fixDir($channel).'.html"'."\n".
					'	LogDir="logs/'.$this->fixDir($channel).'/"'."\n".
					'</channel>'."\n";
		}
		file_put_contents('pisgInclude.cfg',$pisg);
		foreach($this->channels as $channel){
			if(!is_dir('logs/'.$this->fixDir($channel)))mkdir('logs/'.$channel);
		}
	}
	function logLine($buffer,$bufferParts,$nick,$channel){
		if(@substr($bufferParts[2],0,1)!=='#'&&@substr($bufferParts[2],0,2)!==':#')return; //not in channel
		$message=explode(' ',$buffer);
		$i=0;
		while($i++<3) array_shift($message);
		$message=implode(' ',$message);
		$message=substr($message,1);
		$line='['.date('H:i:s').'] ';
		switch(strtolower($bufferParts[1])){
			case 'privmsg':
				if(substr($message,0,7)===chr(1).'ACTION'&&substr($message,-1,1)===chr(1)){ //it's a /me
					$line.='*** '.$nick.' '.substr($message,7,strlen($message)-1);
					break;
				}
				$line.='<'.$nick.'> '.$message;
				break;
			case 'topic':
				$line.='*** '.$nick.' changes topic to \''.$message.'\'';
				break;
			case 'kick':
				$line.='*** '.$bufferParts[3].' was kicked by '.$nick.' ('.$message.')';
				break;
			case 'mode':
				$line.='*** '.$nick.' sets mode: ';
				$i=0;
				while($i++<3) array_shift($bufferParts);
				$line.=implode(' ',$bufferParts);
				break;
			case 'join':
				$line.='*** Joins: ';
				$line.=str_replace('!',' (',substr($bufferParts[0],1));
				$line.=')';
				break;
			default:
				return;
		}
		file_put_contents('logs/'.$this->fixDir($channel).'/'.date('Y-m-d').'.log',$line."\n",FILE_APPEND);
	}
	function send($line){
		return fwrite($this->socket,$line."\n\r");
	}
	function msg($to,$message,$type='PRIVMSG'){
		return $this->send($type.' '.$to.' :'.$message);
	}
	function $this->fixDir($dirName){
		return preg_replace('[^A-Za-z0-9]','_',$dirName);
	}
}
new StatsBot;