<?php
	class photosManagement {
	
		private $dbfile = "photos.db";
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
			
		public function getPhotos($album) {
			$photos = "";
			$i = 0;
			$q = "SELECT path FROM photos WHERE album = '$album'";
			$queryRes = $this->db->query($q);
			
			while ($photo = $queryRes->fetchArray())
			{
				if (!isset($photo['path'])) continue; 
				
				$photos[$i] = $photo['path'];
				$i++;
			}
			return $photos;
		}
		
		public function getAlbums() {
			$albums = "";
			$i = 0;
			$q = "SELECT name, date, cover FROM albums";
			$queryRes = $this->db->query($q);
			
			while ($album = $queryRes->fetchArray())
			{
				if (!isset($album['name'])) continue; 
				
				$albums[$i] = $album;
				$i++;
			}
			return $albums;
		}
	}
	
	$photosManager = new photosManagement();
	$photosManager->configInit();
	$photosManager->dbinit();
	
?>