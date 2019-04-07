<?php
	class homeManagement {
	
		private $dbfile = "netatmo.db";
		private $db = -1;
		private $config;

		public function configInit() {
			$configFile = file("../configWeb", FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
			foreach ($configFile as $option)
			{
				preg_match("/(.+)=(.+)/", $option, $matches);
				if (isset($matches[1]) && null !== $matches[1] && null !== $matches[2]){
					$this->config[$matches[1]] = $matches[2];
				}
			}
		}
	
		public function getOptionFromConfig($option){
			return $this->config[$option];
		}

		public function dbinit() {
			if ($this->db == -1) 
				$this->db = new SQLite3($this->dbfile, 0666);
		}
		
		public function dbclose() {
			if ($this->db != -1) {
				$this->db->close();
				$db = -1;
			}	
		}
	}
	
	$homeManager = new homeManagement();
	$homeManager->configInit();
	$homeManager->dbinit();
	
?>