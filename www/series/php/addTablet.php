<?php

include '../seriesManagement.php';

$tabletManager = new tabletManagement();
$tabletManager->dbinit("../series.db");
$tabletManager->addTablet($_POST['tabletId'], $_POST['tabletIP']);

$tabletManager->dbclose();

?>