<?php
define('BASE_REPORT_DIR', dirname($_SERVER['SCRIPT_FILENAME'])."/reports/db/");

$branch = $_GET['branch'];
if (substr($branch, 0, 3)!='PHP') {
	$branch = "PHP_5_6";
}


include("include/functions.php");

$TITLE = "PHP: QA: PFTT: $branch";
$SITE_UPDATE = date("D M d H:i:s Y T", filectime(__FILE__));
/* $Id$ */

common_header();


// TODO include info about PFTT, link to download build of PFTT

?>
<h1><a href="pftt.php"><?php echo $branch; ?></a></h1>

<p>Choose a PHP revision or build</p>
<?php

$r = scandir(BASE_REPORT_DIR."/$branch");

var_dump($r);

/*

$latest_revision = '';
$mtime = 0;

foreach ( $r as $revision ) {
	if ($revision=="." or $revision=="..")
		continue;
	if (is_dir(BASE_REPORT_DIR."/$branch/$revision")) {
		$mtime = stat(BASE_REPORT_DIR."/$branch/$revision")[9];
		if ($mtime > $latest_revision_mtime) {
			$latest_revision = $revision;
			$latest_revision_mtime = $mtime;
		}
	}
}


?>
<table>
	<tr>
		<td>Latest:</td>
		<td><a href="build.php?branch=<?php echo $branch; ?>&revision=<?php echo $latest_revision; ?>"><?php echo $latest_revision; ?></a></td>
	</tr>
<?php 	<tr>
		<td>New Failures:</td>
		<td>New Crashes:</td>
	</tr>  ?>
</table>
<br/>
<table>
	<?php
	
foreach ( scandir(BASE_REPORT_DIR."/$branch") as $revision ) {
	if ($revision=="." or $revision=="..")
		continue;
	if (is_dir(BASE_REPORT_DIR."/$branch/$revision")) {
	
	
	?>
	<tr>
		<td><a href="build.php?branch=<?php echo $branch; ?>&revision=<?php echo $revision; ?>"><?php echo $revision; ?></a></td>
	</tr>
	<?php
	
	} // end if
}
	
	
	?>
</table>
<?php
*/

common_footer();

?>