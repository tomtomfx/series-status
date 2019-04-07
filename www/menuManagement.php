<?php
	class menuManagement {
	
		private $config;

		public function configInit() {
			$configFile = file("./configWeb", FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
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
	}
	
	$menuManager = new menuManagement();
	$menuManager->configInit();
	
?>