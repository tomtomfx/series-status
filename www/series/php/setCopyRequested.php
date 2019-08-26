<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");
$episode = $_POST['episode'];
$tabletId = $_POST['tabletId'];
$tabletManager->copyRequested($episode, $tabletId, "true");

$tabletManager->dbclose();

?>