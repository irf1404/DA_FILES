<?php
$array = [
	'current' => [], 
	'beta' => [], 
	'alpha' => [], 
	'stable' => []
];
$domain = 'version.directadmin.com';
foreach($array as $key => $value)
{
	$dns = dns_get_record($key.'-'.$domain, DNS_TXT);
	preg_match('/v=(.*)&commit=(.*)&rt/', $dns[0]['txt'], $matches);
	$array[$key]['version'] = $matches[1];
	$array[$key]['commit'] = $matches[2];
}

if(isset($_POST['submit'])):
	$commit = $_POST['commit'];
	$os = $_POST['os'];
	foreach($array as $key => $value)
	{
		if($array[$key]['commit'] == $commit)
		{
			$version = str_replace('.', '', $array[$key]['version']).'_'.$key;
			break;
		}
	}
	$name = 'da_'.$version.'_'.$os.'_'.$commit.'.tar.gz';
	$link = 'https://download.directadmin.com/directadmin_'.$commit.'_'.$os.'.tar.gz';
	file_put_contents($name, file_get_contents($link));
	header('Content-Description: File Transfer');
	header('Content-Type: application/octet-stream');
	header('Content-Disposition: attachment; filename="'.basename($name).'"');
	header('Expires: 0');
	header('Cache-Control: must-revalidate');
	header('Pragma: public');
	header('Content-Length: '.filesize($name));
	flush();
	readfile($name);
	unlink($name);
else:
?>

<html>
	<head>
	</head>
	<body>
		<div style="padding-top:5%; padding-right:20%; padding-left:20%;">
			<h1>DOWNLOAD DIRECTADMIN</h1>
			<form method="POST" action="">
				<select name="commit">
					<option value="<?=$array['current']['commit']?>">CURRENT (version <?=$array['current']['version']?>)</option>
					<?php if($array['beta']['commit']!=$array['current']['commit']): ?>
					<option value="<?=$array['beta']['commit']?>">BETA (version <?=$array['beta']['version']?>)</option>
					<?php endif ?>
					<option value="<?=$array['alpha']['commit']?>">ALPHA (version <?=$array['alpha']['version']?>)</option>
					<option value="<?=$array['stable']['commit']?>">STABLE (version <?=$array['stable']['version']?>)</option>
				</select>
				<select name="os">
					<option value="linux_amd64">linux_amd64</option>
					<option value="linux_arm64">linux_arm64</option>
					<option value="debian10_amd64">debian10_amd64</option>
					<option value="rhel8_amd64">rhel8_amd64</option>
				</select>
				<input type="submit" name="submit" value="DOWNLOAD">
			</form>
		</div>
	</body>
</html>
<?php endif ?>