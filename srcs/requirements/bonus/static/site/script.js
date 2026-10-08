/* ************************************************************************** */
/*                                                                            */
/*                                                        :::      ::::::::   */
/*   script.js                                          :+:      :+:    :+:   */
/*                                                    +:+ +:+         +:+     */
/*   By: ibeltran <ibeltran@student.42madrid.com    +#+  +:+       +#+        */
/*                                                +#+#+#+#+#+   +#+           */
/*   Created: 2026/10/08 10:18:30 by ibeltran          #+#    #+#             */
/*   Updated: 2026/10/08 10:19:12 by ibeltran         ###   ########.fr       */
/*                                                                            */
/* ************************************************************************** */

const CHECK_INTERVAL_MS = 30000;
const TIMEOUT_MS = 5000;

async function checkService(node) {
	const url = node.dataset.check;
	const anyResponse = node.hasAttribute('data-any-response');
	const text = node.querySelector('.status-text');
	const start = performance.now();

	try {
		const response = await fetch(url, {
			method: 'HEAD',
			cache: 'no-store',
			redirect: 'manual',
			credentials: 'omit',
			signal: AbortSignal.timeout(TIMEOUT_MS),
		});
		const ms = Math.round(performance.now() - start);
		const locked = response.status === 401;
		const up = anyResponse || response.ok || response.type === 'opaqueredirect';

		node.classList.toggle('is-up', up && !locked);
		node.classList.toggle('is-locked', locked && !anyResponse);
		node.classList.toggle('is-down', !up && !locked);

		if (locked && !anyResponse) {
			text.textContent = 'Protegido con contraseña';
		} else {
			text.textContent = up ? `Funcionando, ${ms} ms` : `Error ${response.status}`;
		}
	} catch (error) {
		node.classList.remove('is-up', 'is-locked');
		node.classList.add('is-down');
		text.textContent = error.name === 'TimeoutError' ? 'Sin respuesta' : 'No disponible';
	}
}

async function checkAll() {
	const nodes = document.querySelectorAll('[data-check]');
	await Promise.all([...nodes].map(checkService));

	const time = new Date().toLocaleTimeString('es-ES');
	document.getElementById('last-check').textContent =
		`Última comprobación: ${time}. Se repite cada ${CHECK_INTERVAL_MS / 1000} segundos.`;
}

const copyButton = document.getElementById('copy-ftp');

copyButton.addEventListener('click', async () => {
	const command = document.getElementById('ftp-command').textContent;
	try {
		await navigator.clipboard.writeText(command);
		copyButton.textContent = 'Copiado';
	} catch {
		copyButton.textContent = 'No se pudo copiar';
	}
	setTimeout(() => { copyButton.textContent = 'Copiar comando'; }, 2000);
});

document.getElementById('check-now').addEventListener('click', checkAll);

checkAll();
setInterval(checkAll, CHECK_INTERVAL_MS);