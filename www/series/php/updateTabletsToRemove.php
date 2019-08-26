<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");

$content = formComboToCopy("Tablet", $tabletManager, "removeTablet");

$tabletManager->dbclose();

echo json_encode($content);

?>