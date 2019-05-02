<?php

class seriesManagement {

	private $dbfile = "series.db";
	private $db = -1;
	private $config;

	public function configInit() {
		# Website config
		$configFile = file("../secure/configWeb", FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
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
			$this->db = new SQLite3($this->dbfile);
	}
	
	public function dbclose() {
		$this->db->close();
		$this->db = -1;	
	}
		
	public function getEpisodes($removeArchived) {
		$episodes;
		$i = 0;
		
		$q = "SELECT * FROM unseenEpisodes ORDER BY Show, Id";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['Id'])) continue; 
			if ($removeArchived == true and $episode['Archived'] == "TRUE") continue;
			
			$episodes[$i] = $episode;
			$i++;
		}
		return $episodes;
	}
	
	public function getShows($removeArchived) {
		$shows = "";
		$i = 0;
		$q = 'SELECT Show, Archived FROM unseenEpisodes';
		$queryRes = $this->db->query($q);
			
		while ($show = $queryRes->fetchArray())
		{
			if (!isset($show['Show'])) continue; 
			
			if ($removeArchived == true and $show['Archived'] == "TRUE") continue;
			
			$shows[$i] = $show['Show'];
			$i++;
		}
		$shows = array_unique($shows, SORT_STRING);
		return $shows;
	}
}

$seriesManager = new seriesManagement();
$seriesManager->configInit();
$seriesManager->dbinit();

class tabletManagement {

	private $dbfile = "series.db";
	private $db = -1;
	
	public function dbinit() {
		if ($this->db == -1) 
			$this->db = new SQLite3($this->dbfile);
	}
	
	public function dbclose() {
		$this->db->close();
		$this->db = -1;	
	}
		
	public function getEpisodesFromStatus($status, $removeArchived) {
		$episodes;
		$i = 0;
		// Set where depending on the requested status
		$where = "";
		if ($status == "Available"){$where = "IsOnTablet='false' AND CopyRequested='false'";}
		else if ($status == "On tablet"){$where = "IsOnTablet='true'";}
		else if ($status == "Copy requested"){$where = "CopyRequested='true'";}
		else return 0;
		
		$q = "SELECT * FROM unseenEpisodes WHERE ".$where." ORDER BY Show, Id";
		$queryRes = $this->db->query($q);
		
		while ($episode = $queryRes->fetchArray())
		{
			if (!isset($episode['Id'])) continue; 
			if ($removeArchived == true and $episode['Archived'] == "TRUE") continue;
			
			$episodes[$i] = $episode;
			$i++;
		}
		if (isset($episodes)){
			return $episodes;	
		}
		return null;
	}
	
	public function getShows($removeArchived) {
		$shows = "";
		$i = 0;
		$q = 'SELECT Show, Archived FROM unseenEpisodes';
		$queryRes = $this->db->query($q);
			
		while ($show = $queryRes->fetchArray())
		{
			if (!isset($show['Show'])) continue; 
			
			if ($removeArchived == true and $show['Archived'] == "TRUE") continue;
			
			$shows[$i] = $show['Show'];
			$i++;
		}
		$shows = array_unique($shows, SORT_STRING);
		return $shows;
	}
	
	public function copyRequested($episodeId, $tablet, $doCopy) {
		$q = "UPDATE unseenEpisodes SET CopyRequested='".$doCopy."', Tablet='".$tablet."' WHERE Id='".$episodeId."'";
		// var_dump ($q);
		$this->db->query($q);
	}
	
	public function addTablet ($id, $ipAddr, $user, $password)
	{
		// Check if table Tablets exists. If not create it.
		$q = "SELECT COUNT(*) FROM sqlite_master WHERE name='Tablets' and type='table'";
		$queryRes = $this->db->query($q);
		$tableExists = $queryRes->fetchArray();
		if ($tableExists[0] == 0){
			$this->db->exec('CREATE TABLE Tablets (id TEXT PRIMARY KEY, ip TEXT, ftpUser TEXT, ftpPassword TEXT, status TEXT)');
		}
		// Insert new tablet into database
		// Check if id already exists
		$q = "SELECT COUNT(id) FROM Tablets WHERE id='$id'";
		$queryRes = $this->db->query($q);
		$tabletExists = $queryRes->fetchArray();
		if ($tabletExists[0] == 0){
			$q = 'INSERT INTO Tablets (id, ip, ftpUser, ftpPassword) VALUES ("'.$id.'", "'.$ipAddr.'", "'.$user.'", "'.$password.'")';
			$this->db->exec($q);
		}
	}
	public function getTablets()
	{
		$tablets;
		$i = 0;
		$q = 'SELECT * FROM Tablets';
		$queryRes = $this->db->query($q);
		if ($queryRes != false)
		{
			while ($tablet = $queryRes->fetchArray())
			{
				$tablets[$i] = $tablet;
				$i++;
			}
		}
		else {$tablets = 0;}
		if (isset($tablets)){
			return $tablets;	
		}
		return null;
	}
	public function removeTablet ($id)
	{
		$q = 'DELETE FROM Tablets WHERE id=\''.$id.'\'';
		$queryRes = $this->db->query($q);
	}
}

$tabletManager = new tabletManagement();
$tabletManager->dbinit();


//**********************************************************************************************************************// fonctions PHP
// Write all episodes 
function printEpisodesToWatch ($seriesManager)
{

	$episodes = $seriesManager->getEpisodes(true);
	$nbEpisodes = count($episodes);
	
	$glyph = "glyphicon-folder-open";	
	echo'
		<div class="panel panel-default" id="panelGlobal">
			<div class="panel-heading" id="panelHead">
				<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>Episodes to see<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
			</div>
			<table class="table table-hover">
			<thead><tr>
				<th class="col-xs-2">Show</th>
				<th class="col-xs-1">Episode</th>
				<th class="col-xs-4">Title</th>
				<th class="col-xs-2">Status</th>
				<th id="CenteredTitle" class="col-xs-2">Actions</th>
			</tr></thead>
			<tbody>								
	';
	foreach ($episodes as $episode)
	{
		$serieName = $episode['Show'];
		$serieNameUnderscore = preg_replace('/ /', '_', $serieName);
		$serieNameUnderscore = preg_replace('/\(/', '\(', $serieNameUnderscore);
		$serieNameUnderscore = preg_replace('/\)/', '\)', $serieNameUnderscore);
		$episodeID = $episode['Id'];
		$IdBetaseries = $episode['IdBetaseries'];
		preg_match("#.+ - (.+)#", $episodeID, $matches);
		$episodeNumber = $matches[1];
		$episodeTitle = '&nbsp;';
		if (isset($episode['Title'])) $episodeTitle = $episode['Title'];
		$epStatus = $episode['Status'];
		$label = "info";
		switch ($epStatus)
		{
			case "To be watched":
				$label = "success";
				break;
			case "No subtitles found":
				$label = "warning";
				break;
			case "Download launched":
				$label = "info";
				break;
			case "Download failed":
				$label = "danger";
				break;
		}
		$action = "";
		if ($label == "success")
		{
			$action = '<a id="epAction" href="../cgi-bin/update.cgi?ep='.$serieNameUnderscore.'-'.$episodeNumber.'-'.$IdBetaseries.'"><span class="glyphicon glyphicon-eye-open"></span></a>';
			// $action = $action.'<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=copy"><span class="glyphicon glyphicon-plus"></span></a>';
		}
		echo'
					<tr>
						<td id="show" class="col-xs-2"><img id="banniere2" class="img-responsive" src="../images/banners/'.$serieName.'" alt="'.$serieName.'"></td>
						<td id="epNumber" class="col-xs-1">'.$episodeNumber.'</td>
						<td id="epTitle" class="col-xs-4">'.$episodeTitle.'</td>
						<td id="epStatus" class="col-xs-2"><span class="label label-'.$label.'">'.$epStatus.'</span></td>
						<td id="epNext" class="col-xs-2" text-align="center">'.$action.'</td>
					</tr>
		';
	}
	echo'
				</tbody>
			</table>
		</div>
	';
}						

// Form combo
function formComboToCopy ($label, $tabletManager)
{
	$tablets = $tabletManager->getTablets();
	echo'
								<div class="row">
									<div class="form-group">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.'</label>
										<div class="col-xs-6">
											<select name="tabletId" class="form-control">
	';
	foreach ($tablets as $tablet) {
		echo'
											<option>'.$tablet['id'].'</option>
		';
	}
	echo'
											</select>
										</div>
									</div>
								</div>
	';
}

// Form combo
function formComboToArchive ($label, $showsFound)
{
	echo'
								<div class="row">
									<div class="form-group">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.'</label>
										<div class="col-xs-6">
											<select name="showId" class="form-control">
	';
	foreach ($showsFound as $key => $id) {
		echo'
											<option value="'.$id.'">'.$key.'</option>
		';
	}
	echo'
											</select>
										</div>
									</div>
								</div>
	';
}

// Get a random image to diplay it as background
function getRandomBackground($dir)
{
	$images = array();
	$list = scandir($dir);
	foreach ($list as $file) {
		if (!isset($img)) {
			$img = '';
		}
		if (is_file($dir . '/' . $file)) {
			$tmp = explode('.', $file);
			$ext = end($tmp);
			if ($ext == 'jpg') 
			{
				array_push($images, $file);
				$img = $file;
			}
		}
	}
	if ($img != '') {
		$img = array_rand($images);
		$img = $images[$img];
	}
	$img = str_replace("'", "\'", $img);
	$img = str_replace(" ", "%20", $img);
	return $img;
}

// Write all episodes from a status 
function printEpisodesToCopy ($status, $tabletManager)
{

	$episodes = $tabletManager->getEpisodesFromStatus($status, true);
	if (!empty($episodes)){
		$nbEpisodes = count($episodes);
	}
	else{$nbEpisodes = 0;}
	
	$glyph = "glyphicon-folder-open";
	if ($status == "On tablet"){$glyph = "glyphicon-phone";} 
	elseif ($status == "Copy requested"){$glyph = "glyphicon-save";} 
	
	if (is_array($episodes) AND $status == "Available")
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>'.$status.'<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
				</div>
				<table class="table table-condensed">
				<thead><tr>
					<th class="col-xs-4">Show</th>
					<th class="col-xs-1">Episode</th>
					<th class="col-xs-6">Title</th>
					<th class="col-xs-1">Actions</th>
				</tr></thead>
				<tbody>								
		';
		foreach ($episodes as $episode)
		{
			$show = $episode['Show'];
			$episodeID = $episode['Id'];
			preg_match("#.+ - (.+)#", $episodeID, $matches);
			$episodeNumber = $matches[1];
			$episodeTitle = '&nbsp;';
			if (isset($episode['Title'])) $episodeTitle = $episode['Title'];

			$status = '&nbsp;';
			$action = '<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=copy"><span class="glyphicon glyphicon-plus"></span></a>';			
			echo'
						<tr>
							<td class="col-xs-1">'.$show.'</td>
							<td class="col-xs-2">'.$episodeNumber.'</td>
							<td class="col-xs-6">'.$episodeTitle.'</td>
							<td class="col-xs-1" text-align="center">'.$action.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}

	elseif (is_array($episodes) AND ($status == "On tablet" OR $status == "Copy requested"))
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon '.$glyph.'" id="panelGlyph"></span>'.$status.'<span class="badge badge-primary" id="nbEpBadge">'.$nbEpisodes.'</span></h2>
				</div>
				<table class="table table-condensed">
				<thead><tr>
					<th class="col-xs-4">Show</th>
					<th class="col-xs-1">Episode</th>
					<th class="col-xs-4">Title</th>
					<th class="col-xs-2">Tablet</th>
					<th class="col-xs-1">Actions</th>
				</tr></thead>
				<tbody>								
		';
		foreach ($episodes as $episode)
		{
			$show = $episode['Show'];
			$episodeID = $episode['Id'];
			preg_match("#.+ - (.+)#", $episodeID, $matches);
			$episodeNumber = $matches[1];
			$tablet = $episode['Tablet'];
			$episodeTitle = '&nbsp;';
			if (isset($episode['Title'])) $episodeTitle = $episode['Title'];

			if ($episode['CopyRequested'] == "true")
			{
				$status = 'Copy requested';
				$action = '<a id="epAction" href="./tablet.php?id='.urlencode($episode['Id']).'&action=cancel" text-align="center"><span class="glyphicon glyphicon-remove"></span></a>';
			}
			else if ($episode['IsOnTablet'] == "true")
			{
				$status = 'Copied';
				$action = '&nbsp;';
			}
			
			echo'
						<tr>
							<td class="col-xs-4">'.$show.'</td>
							<td class="col-xs-1">'.$episodeNumber.'</td>
							<td class="col-xs-4">'.$episodeTitle.'</td>
							<td class="col-xs-2">'.$tablet.'</td>
							<td class="col-xs-1" text-align="center">'.$action.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}
}						

// Write all episodes from a status 
function printTablets ($tabletManager)
{
	$tablets = $tabletManager->getTablets();
	if (is_array($tablets))
	{
		echo'
			<div class="panel panel-default" id="panelGlobal">
				<div class="panel-heading" id="panelHead">
					<h2 class="panel-title" id="panelTitle"><span class="glyphicon glyphicon-phone" id="panelGlyph"></span>Tablets</h2>
				</div>
				<table class="table table-condensed">
					<thead><tr>
						<th class="col-xs-6">Name</th>
						<th class="col-xs-6">Status</th>
					</tr></thead>
					<tbody>								
		';
		foreach ($tablets as $tablet)
		{
			$tabletName = $tablet['id'];
			$tabletStatus = "<span class=\"label label-warning\">Connection lost</span>";
			if ($tablet['status'] == 'OK'){$tabletStatus = "<span class=\"label label-success\">Available</span>";}
			echo'
						<tr>
							<td class="col-xs-6">'.$tabletName.'</td>
							<td class="col-xs-6">'.$tabletStatus.'</td>
						</tr>
			';
		}
		echo'
					</tbody>
				</table>
			</div>
		';
	}
}						

// Form text 
function formText ($label, $input, $status, $value, $editable)
{
	$formGroup = "form-group";
	$inputField = '<input name="'.$input.'" type="text" class="form-control" value="'.$value.'">';
	if ($editable == "false"){$inputField = '<input name="'.$input.'" type="text" class="form-control" value="'.$value.'" readonly>';}
	if ($status == "failed" AND $value == ""){$formGroup = "form-group has-error";}
	echo'
								<div class="row">
									<div class="'.$formGroup.'">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.' </label>
										<div class="col-xs-6">
											'.$inputField.'
										</div>
									</div>
								</div>
	';
}

// Form password 
function formPassword ($label, $input, $status, $value)
{
	$formGroup = "form-group";
	if ($status == "failed" AND $value == ""){$formGroup = "form-group has-error";}
	echo'
								<div class="row">
									<div class="'.$formGroup.'">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.' </label>
										<div class="col-xs-6">
											<input name="'.$input.'" type="password" class="form-control" value="'.$value.'">
										</div>
									</div>
								</div>
	';
}

// BetaSeries authentication
function betaSeriesAuthenticate ($seriesManager)
{
	$betaSeriesKey = $seriesManager->getOptionFromConfig('betaSeriesKey');
	$betaSeriesLogin = $seriesManager->getOptionFromConfig('betaSeriesLogin');
	$betaSeriesPassword = $seriesManager->getOptionFromConfig('betaSeriesPassword');
	$url = "http://api.betaseries.com";
	$auth = "$url/members/auth?login=$betaSeriesLogin&password=$betaSeriesPassword";
	$token = "";

	$options = array(
		'http' => array(
			'method'  => 'POST',
			'header'  => array(
				"Accept: application/json",
				"X-BetaSeries-Version: 2.2",
				"X-BetaSeries-Key: $betaSeriesKey"
			)
		)
	);	

	$context  = stream_context_create($options);
	$result = file_get_contents($auth, false, $context);

	preg_match ("#\"token\": \"(.+)\"#", $result, $matches);
	if (isset($matches[1]) && $matches[1] !== null){
		return $matches[1];
	}
	else {return 0;}
}

// Get list of shows from the search
function getShowList ($searchShow, $seriesManager)
{
	$showsFound;
	$betaSeriesKey = $seriesManager->getOptionFromConfig('betaSeriesKey');
	$url = "http://api.betaseries.com";
	$token = betaSeriesAuthenticate ($seriesManager);
	$searchShow = urlencode($searchShow);
	$search = "$url/shows/search?title=$searchShow&summary=true&token=$token";
	$options = array(
		'http' => array(
			'method'  => 'GET',
			'header'  => array(
				"Accept: application/json",
				"X-BetaSeries-Version: 3.0",
				"X-BetaSeries-Key: $betaSeriesKey"
			)
		)
	);

	$context  = stream_context_create($options);
	$result = file_get_contents($search, false, $context);
	$shows = json_decode($result, true);
	foreach ($shows['shows'] as $show)
	{
		$showsFound[$show['title']] = $show['id'];
	}
	if (isset($showsFound)){
		return($showsFound);	
	}
	return(0);
}

// Get list of shows followed
function getCurrentShowList ($seriesManager)
{
	$showsFound;
	$betaSeriesKey = $seriesManager->getOptionFromConfig('betaSeriesKey');
	$url = "http://api.betaseries.com";
	$token = betaSeriesAuthenticate ($seriesManager);

	# Get active shows
	$search = "$url/shows/member?status=active&token=$token";
	$options = array(
		'http' => array(
			'method'  => 'GET',
			'header'  => array(
				"Accept: application/json",
				"X-BetaSeries-Version: 3.0",
				"X-BetaSeries-Key: $betaSeriesKey"
			)
		)
	);
	$context  = stream_context_create($options);
	$result = file_get_contents($search, false, $context);
	$shows = json_decode($result, true);
	foreach ($shows['shows'] as $show)
	{
		$showsFound[$show['title']] = $show['id'];
	}

	# Get current shows
	$search = "$url/shows/member?status=current&token=$token";
	$options = array(
		'http' => array(
			'method'  => 'GET',
			'header'  => array(
				"Accept: application/json",
				"X-BetaSeries-Version: 3.0",
				"X-BetaSeries-Key: $betaSeriesKey"
			)
		)
	);
	$context  = stream_context_create($options);
	$result = file_get_contents($search, false, $context);
	$shows = json_decode($result, true);
	foreach ($shows['shows'] as $show)
	{
		$showsFound[$show['title']] = $show['id'];
	}

	if (isset($showsFound)){
		ksort($showsFound);
		return($showsFound);	
	}
	return(0);
}

// Form combo
function formComboToAdd ($label, $showsFound)
{
	echo'
								<div class="row">
									<div class="form-group">
										<label class="col-xs-offset-1 col-xs-3 control-label">'.$label.'</label>
										<div class="col-xs-6">
											<select name="showId" class="form-control">
	';
	foreach ($showsFound as $key => $id) {
		echo'
											<option value="'.$id.'">'.$key.'</option>
		';
	}
	echo'
											</select>
										</div>
									</div>
								</div>
	';
}

function getFilesMissingSubtitles($seriesManager)
{
	$downloadFolder = $seriesManager->getOptionFromConfig('downloadFolder');
	$files = scandir($downloadFolder);
	// Remove not video files
	$extensions_valid = array('mkv', 'mp4', 'avi');
	foreach ($files as $filename)
	{
		$fileExtension = strtolower(substr(strrchr($filename, '.') ,1));
		if (!in_array($fileExtension,$extensions_valid)){$files = \array_diff($files, [$filename]);}
	}
	return($files);
}

function storeSubFile ($seriesManager, $subFile)
{
	$downloadFolder = $seriesManager->getOptionFromConfig('downloadFolder');
	$maxsize = 500000;
	$error = 0;
	// Check extension
	$extensions_valid = array( 'srt');
	$extension_upload = strtolower(substr(strrchr($subFile['name'], '.') ,1));
	if (!in_array($extension_upload,$extensions_valid)) {$error = "Incorrect extension";}
	// Check transfer status
	elseif ($subFile['error'] > 0) {$error = "Error during transfert ".$_FILES['icone']['error'];}
	// Check file size
	elseif ($subFile['size'] > $maxsize) {$error = "File size is too big";}
	else 
	{
		$filename = $downloadFolder.$subFile['name'];
		$result = move_uploaded_file($subFile['tmp_name'],$filename);
		if ($result) {$error="success";}
		else {$error="transfer failed";}
	}
	return $error;
}

//**********************************************************************************************************************// functions PHP


	
?>