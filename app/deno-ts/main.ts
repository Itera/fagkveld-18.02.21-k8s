import { Application, Router } from 'https://deno.land/x/oak/mod.ts';

const PORT = 8090;

const app = new Application();

const router = new Router();

router.get('/hello', ({ response }: { response: any }) => {
    const secret = Deno.env.get('SECRET');
    response.body = `world, ${secret} \n`;
});

app.use(router.routes());
app.use(router.allowedMethods());

console.log(`Server running on port : ${PORT}`);

await app.listen(`0.0.0.0:${PORT}`);
