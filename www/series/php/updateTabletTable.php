<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");

$tableName = $_POST['tableName'];
$panelId = $_POST['panelId'];
$content = printEpisodesToCopy($tableName, $tabletManager, $panelId);

$tabletManager->dbclose();

echo json_encode($content);

?>